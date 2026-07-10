# AI Microservice — Production-Ready Deployment Pipeline

A FastAPI + PostgreSQL microservice, containerized and deployed to AWS EKS
with a full CI/CD, monitoring, logging, and security stack.

**Full architecture diagram:** [`docs/architecture.md`](docs/architecture.md)
**Security deep-dive:** [`docs/security-notes.md`](docs/security-notes.md)



## Repo layout
```
app/                FastAPI application + tests
docker/              Dockerfile (multi-stage) + docker-compose.yml
k8s/                 Raw Kubernetes manifests (namespace → HPA, ordered 00-10)
helm/ai-microservice/  Helm chart wrapping the above (bonus)
terraform/           VPC, security groups, EKS cluster + node group
.github/workflows/   CI/CD pipeline (GitHub Actions)
monitoring/          Prometheus/Grafana values, ServiceMonitor, alert rules
logging/             Loki + Promtail values
docs/                Architecture diagram, security notes
```

## Stack
| Layer | Choice |
|---|---|
| App | FastAPI (Python 3.12), SQLAlchemy, Postgres 16 |
| Container | Docker multi-stage, non-root, healthcheck |
| Orchestration | Kubernetes (EKS) — Deployment, HPA, Ingress, NetworkPolicy |
| IaC | Terraform (VPC, subnets, SGs, EKS, node group) |
| CI/CD | GitHub Actions — lint → test → build → scan → push → deploy |
| Monitoring | Prometheus + Grafana + Alertmanager |
| Logging | Loki + Promtail |
| Security | Trivy (CI), RBAC, NetworkPolicy, non-root, OIDC — Falco documented as bonus |

---

## 1. Run locally (5 minutes)
```bash
docker compose -f docker/docker-compose.yml up --build
curl http://localhost:8000/health
curl -X POST http://localhost:8000/predict -H "Content-Type: application/json" \
  -d '{"input_text":"hello"}'
```
Interactive API docs: `http://localhost:8000/docs`

### Local Execution Proofs
* **Docker Compose Logs**:
  ![Docker Compose Local Logs](docs/Docker%20Compose%20Startup%20Logs.png)
* **PostgreSQL Database Storage (Adminer View)**:
  ![Adminer Database Table Output](docs/adminer.png.png)

## 2. Provision AWS infra with Terraform (~15-20 min, mostly EKS wait time)
```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Point kubectl at the new cluster
aws eks update-kubeconfig --region ap-south-1 --name ai-microservice-eks
```
> Uses local state by default for speed. For real production, uncomment the
> `backend "s3"` block in `versions.tf` (see [State & DR](#terraform-state--disaster-recovery) below) — create the S3 bucket + DynamoDB table once, then `terraform init` again to migrate state.

### AWS EKS Cluster Provisioning Proofs
* **Active EKS Cluster Status**:
  ![AWS EKS Active Console](docs/aws_eks_active_v2.png)
* **EKS Cluster Details**:
  ![AWS EKS Detail](docs/aws_eks_detail_v2.png)
* **EKS Pods Running Verification**:
  ![Kubernetes Pods Running Status](docs/k8s_pods_running_v2.png)
* **Manual Deploy Command Logs**:
  ![Kubernetes Manual Apply Output](docs/k8s_manual_apply_v2.png)

## 3. Build & push the image
```bash
aws ecr create-repository --repository-name ai-microservice --region ap-south-1
aws ecr get-login-password --region ap-south-1 | docker login --username AWS \
  --password-stdin <account-id>.dkr.ecr.ap-south-1.amazonaws.com

docker build -t <account-id>.dkr.ecr.ap-south-1.amazonaws.com/ai-microservice:v1 \
  -f docker/Dockerfile .
docker push <account-id>.dkr.ecr.ap-south-1.amazonaws.com/ai-microservice:v1
```

## 4. Deploy to Kubernetes

**Option A — raw manifests**
```bash
# edit k8s/05-deployment.yaml: replace <YOUR_REGISTRY> with your ECR URL
kubectl apply -f k8s/
kubectl get pods -n ai-microservice -w
```

**Option B — Helm (bonus, recommended)**
```bash
helm upgrade --install ai-microservice ./helm/ai-microservice \
  --namespace ai-microservice --create-namespace \
  --set image.repository=<account-id>.dkr.ecr.ap-south-1.amazonaws.com/ai-microservice \
  --set image.tag=v1
```

## 5. Monitoring & logging
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f monitoring/prometheus-values.yaml
kubectl apply -f monitoring/servicemonitor.yaml -f monitoring/alert-rules.yaml

helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack -n logging --create-namespace \
  -f logging/loki-stack-values.yaml

# Access Grafana
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# login: admin / changeme-use-secret-in-prod  (rotate before real use)
```

### Centralized Monitoring & Logging Proofs
* **Grafana Dashboard**:
  ![Grafana Dashboard](docs/grafana_dashboard_v2.png)
* **Loki Logs Explorer**:
  ![Loki logs stream](docs/loki_logs_v2.png)

## 6. CI/CD
Push to `main` triggers `.github/workflows/ci-cd.yaml`:
**lint (flake8/black) → test (pytest + ephemeral Postgres) → docker build →
Trivy scan (blocks on CRITICAL/HIGH) → push to ECR → `helm upgrade` on EKS**

### CI/CD Automation Proofs
* **GitHub Actions Green CI Logs**:
  ![GitHub Actions Green Pipeline](docs/github_actions_ci_v2.png)
* **Trivy Container Vulnerability Scan Logs**:
  ![Trivy Scan Logs](docs/github_trivy_logs.png.png)

Required GitHub repo secrets: `AWS_ACCOUNT_ID`, `AWS_REGION`, `AWS_OIDC_ROLE_ARN`.

---

## Terraform state & disaster recovery
- **State**: local by default for a fast demo; production uses S3 backend +
  DynamoDB lock table (commented block in `terraform/versions.tf`) so state
  is versioned, encrypted, and safe for team/CI use — no "who has the
  `.tfstate` file" problem.
- **DR**: EKS control plane is AWS-managed (multi-AZ by default). Worker
  nodes span 2 AZs via `aws_eks_node_group` on private subnets across
  `var.azs`. Postgres here runs as a StatefulSet with a PVC for the demo;
  production should move it to **RDS Multi-AZ** with automated snapshots —
  the `db_sg` security group in `terraform/security-groups.tf` is already
  scoped for that migration. Recovery playbook: restore RDS from latest
  automated snapshot (point-in-time recovery), `terraform apply` to rebuild
  infra from code if a region/account is lost, `helm upgrade --install` to
  redeploy app state from the last known-good image tag in ECR.

## Scaling
- **Horizontal**: HPA scales pods 3→10 on CPU (65%) and memory (75%)
  thresholds, with fast scale-up (30s window) and conservative scale-down
  (5min window) to avoid flapping.
- **Cluster-level**: add Cluster Autoscaler (or Karpenter) watching the node
  group so new EC2 nodes join automatically when pods can't be scheduled —
  not included here to keep the 6-hour scope realistic, noted as a
  production improvement below.

## Cost optimization
- Node group uses `t3.medium` ON_DEMAND by default; switch `capacity_type`
  to `SPOT` in `terraform/eks.tf` for non-prod environments (~60-70% savings).
- Single NAT Gateway (not one per AZ) — acceptable cost/resilience trade-off
  for a demo; production would add one per AZ for HA at higher cost.
- Loki over ELK specifically to avoid running an Elasticsearch cluster
  (JVM heap, multiple data nodes) for log storage — see `logging/README.md`.
- HPA + Cluster Autoscaler together mean you pay for capacity you're
  actually using, not a fixed peak-sized cluster.

## Debugging playbook
```bash
kubectl get pods -n ai-microservice                     # pod status
kubectl describe pod <pod> -n ai-microservice            # events, probe failures
kubectl logs <pod> -n ai-microservice --previous          # crash logs
kubectl exec -it <pod> -n ai-microservice -- sh           # shell in (if not read-only-fs blocked)
kubectl top pods -n ai-microservice                       # resource usage vs limits
kubectl rollout undo deployment/ai-microservice -n ai-microservice  # instant rollback
```
Grafana dashboards + Loki logs give the "why" once `kubectl` gives the "what."

## Limitations (honest, given the 6-hour scope)
- Postgres runs in-cluster (StatefulSet) rather than RDS — fine for a demo,
  not for real production data durability/backup guarantees.
- Terraform provisions infra only; it does not also install Helm releases
  (kept Terraform and app deployment decoupled on purpose — simpler state,
  clearer CI/CD ownership boundary).
- No Cluster Autoscaler/Karpenter, no WAF, no image signing (cosign) —
  documented as next steps, not implemented, to hit the time budget.
- EKS public endpoint is open (`0.0.0.0/0`) for demo reachability; must be
  restricted to known CIDRs (VPN/office) before real production use.
- Grafana admin password is a plaintext Helm value — must move to a K8s
  Secret / Secrets Manager before real use.

## Production improvements (next steps)
1. Migrate Postgres to RDS Multi-AZ with automated backups + PITR.
2. Add Cluster Autoscaler or Karpenter for node-level elasticity.
3. External Secrets Operator syncing from AWS Secrets Manager, with rotation.
4. Image signing (cosign/Sigstore) + admission control (Kyverno/OPA Gatekeeper).
5. Falco for runtime threat detection (install command in `docs/security-notes.md`).
6. Multi-environment Terraform workspaces (dev/staging/prod) + S3 state backend.
7. Blue/green or canary deploys (Argo Rollouts) instead of plain rolling update.
8. WAF + restricted EKS API endpoint CIDRs.
