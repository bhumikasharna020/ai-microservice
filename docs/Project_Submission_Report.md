# Project Submission Report: Production-Ready AI Microservice Deployment

## 📋 Project Metadata
* **GitHub Repository URL**: [https://github.com/bhumikasharna020/ai-microservice](https://github.com/bhumikasharna020/ai-microservice)
* **AWS EKS Cluster Name**: `ai-microservice-eks`
* **Kubernetes Namespace**: `ai-microservice`
* **Local Test Environment**: Docker Desktop (Docker Compose)
* **CI/CD Platform**: GitHub Actions

---

## 🏛️ Section 1: Architecture & Design Flows

### 1. High-Level Architectural Flow (System Design)
The AI Microservice utilizes a modern decoupled microservices design patterns optimized for security, observability, and horizontal scalability on Kubernetes:

```
[GitHub Actions CI/CD]
      │ (Pushes Docker Image)
      ▼
[GitHub Container Registry (GHCR)]
      │
      ▼
[AWS EKS Cluster (Control Plane)] ◄───► [Worker Node Groups (EC2)]
      │
      ├─► [FastAPI Pod (Replica 1)] ◄───► [PostgreSQL StatefulSet Pod]
      ├─► [FastAPI Pod (Replica 2)] ◄───► [Adminer Database Client Pod]
      │
      ├─► [Prometheus Monitor Service]
      └─► [Loki Centralized Logs Explorer]
```

### 2. Low-Level Network Routing & Security Flow
To enforce zero-trust security inside EKS, default network policies are implemented to restrict cross-namespace traffic:

```
                  [External Traffic]
                          │
                          ▼
              [Ingress NGINX Controller]
                          │ (Allows Port 8000 only)
                          ▼
                 [FastAPI Pods (App)]
                          │ (Allows Port 5432 only)
                          ▼
                [PostgreSQL StatefulSet]
```

---

## 🛠️ Section 2: Deliverables & Verification Checklist

### Phase 1: Local Containerization (Docker)
We configured a multi-stage Docker build running under a non-root user (`appuser` UID 1000) for security hardening. 
* **Folder Structure**:
  ![Figure 1.1: GitHub Repository Folder Structure](Project%20Metadata.png)
* **Docker Compose local run**:
  ![Figure 2.1: Docker Compose Local Startup Logs](Docker%20Compose%20Startup%20Logs.png)
* **FastAPI Swagger API UI Page**:
  ![Figure 2.2: FastAPI Swagger Documentation Panel](FastAPI%20Swagger%20UI.png)
* **PostgreSQL Database Storage Verification**:
  ![Figure 2.3: Adminer predictions Database Table Output](adminer.png.png)
* **Docker Hub Registry Push Verification**:
  ![Figure 2.4: Pushed Image confirmation tags on Docker Hub Registry](Docker%20Hub%20Repository%20Tags.png)

---

### Phase 2: Infrastructure as Code (Terraform)
Automated cloud provisioning scripts deploy EKS, Node groups, private/public subnets, NAT Gateway and Route tables securely.
* **AWS EKS Cluster Active Status**:
  ![Figure 3.1: AWS Console active EKS Cluster Status](aws_eks_active_v2.png)
* **AWS EKS Cluster Overview Details**:
  ![Figure 3.2: EKS details with Endpoint and OpenID Connect URLs](aws_eks_detail_v2.png)

---

### Phase 3: Automation CI/CD Pipeline (GitHub Actions)
Our pipeline validates code quality using Ruff linter, runs pytest coverage suite, scans the image with Trivy security tool, and pushes the package to GHCR.
* **GitHub Actions Green CI Logs**:
  ![Figure 4.1: Succeeded GitHub Actions CI Pipeline job logs](github_actions_ci_v2.png)
* **Trivy Container Vulnerability Scan Logs**:
  ![Figure 4.2: Trivy vulnerability report output](github_trivy_logs.png.png)

---

### Phase 4: Kubernetes Hardening & Security
We configured strict memory/CPU resource constraints, container startup/readiness/liveness probes, RBAC roles, and Network Policies.
* **RBAC Setup**:
  ![Figure 5.1: ServiceAccount and Roles configurations](k8s_rbac.png.png)
* **Probes & Limits**:
  ![Figure 5.2: CPU/Memory requests vs limits and startup/readiness/liveness checks](k8s_limits.png.png)
* **Network Policies**:
  ![Figure 5.3: Strict Network Policy block rules](k8s_networkpolicy.png.png)
  ![Figure 5.4: PostgreSQL Ingress Network Policy rules](k8s_networkpolicy2.png.png)
* **EKS Pods & Services Running**:
  ![Figure 5.5: Live EKS Namespace Pods and Services Status Check](k8s_pods_running_v2.png)
* **Manual Apply Commands Output**:
  ![Figure 5.6: Kubernetes Manual manifest apply CLI output](k8s_manual_apply_v2.png)

---

### Phase 5: Centralized Observability & Logging
Centralized telemetry dashboards monitor cluster behavior using Prometheus metrics, Grafana charts, and Loki log streams.
* **Grafana Dashboard**:
  ![Figure 6.1: Live Grafana EKS Pod Metrics Monitor](grafana_dashboard_v2.png)
* **Loki Logs Stream**:
  ![Figure 6.2: Centralized Logging Stream logs in Grafana Explore](loki_logs_v2.png)

---

## 🛡️ Section 3: Cost Optimization & Teardown Protocol
EKS nodes and public gateways generate operational costs. Under cloud engineering best practices, we performed the verification tests, captured configuration layouts, and ran `terraform destroy` to clear EKS resources.
* **Final Cluster status check**:
  ```json
  {
      "clusters": []
  }
  ```
* All resources were safely terminated to secure cloud budget constraints.

---

## 📈 Section 4: Future Production Recommendations
1. **Dynamic Secrets Manager**: Rotate DB passwords using AWS Secrets Manager instead of static ConfigMaps.
2. **Autoscaling (KEDA)**: Replace standard HPA with KEDA (Kubernetes Event-driven Autoscaling) to scale microservices based on active HTTP requests queue sizes.
3. **IAM Roles for Service Accounts (IRSA)**: Grant pod-level AWS API access permissions instead of EC2 Node roles for improved isolation.
