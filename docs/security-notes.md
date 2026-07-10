# Security Hardening — What's Implemented & Bonus Tools

## Implemented in this repo
- **Non-root containers**: Dockerfile creates `appuser` (uid 1000); K8s `securityContext.runAsNonRoot: true`.
- **Read-only root filesystem** + all Linux capabilities dropped (`k8s/05-deployment.yaml`).
- **RBAC**: dedicated ServiceAccount with a minimal `Role` (get/list/watch configmaps only) — no cluster-admin, no wildcard verbs.
- **Secrets**: separated from ConfigMap, never baked into the image; production note in `k8s/02-secret.yaml` to use External Secrets Operator / AWS Secrets Manager instead of raw K8s Secrets.
- **NetworkPolicy**: default-deny-all, then explicit allow rules — app only reachable from ingress-nginx + monitoring namespaces, Postgres only reachable from the app.
- **Resource requests/limits** on every container — prevents noisy-neighbor and OOM cluster-wide impact.
- **Liveness/Readiness/Startup probes** — bad pods get cycled out of the Service automatically.
- **PodDisruptionBudget** — guarantees min 2 pods survive voluntary disruptions (node drains, cluster upgrades).
- **CI/CD image scanning**: Trivy scans every image for CRITICAL/HIGH CVEs and **fails the pipeline** if found.
- **OIDC federation for CI**: GitHub Actions assumes an AWS IAM role via OIDC — no long-lived AWS access keys stored as GitHub secrets.

## Bonus (documented, install commands provided)
### Trivy (already wired into CI/CD — see `.github/workflows/ci-cd.yaml`)
Also runnable ad hoc against the cluster:
```bash
trivy k8s --report summary cluster
```

### Falco (runtime threat detection)
```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n falco --create-namespace \
  --set driver.kind=ebpf
```
Falco watches syscalls in real time and alerts on things static scanning can't
catch — e.g. a shell spawned inside a running container, unexpected outbound
connections, or writes to sensitive paths.

## What's still needed for a real production rollout
- Pod Security Admission (`restricted` profile) enforced at namespace level.
- Image signing + verification (cosign / Sigstore) before deploy.
- Secrets via External Secrets Operator synced from AWS Secrets Manager, with rotation.
- WAF in front of the ALB/Ingress (AWS WAF or ModSecurity).
- Restrict EKS public endpoint access to known CIDRs (currently `0.0.0.0/0` for demo reachability).
