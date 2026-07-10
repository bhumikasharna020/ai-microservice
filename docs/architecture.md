# Architecture

```mermaid
flowchart TB
    subgraph Internet
        User[User / Client]
    end

    subgraph AWS["AWS Cloud - ap-south-1"]
        subgraph VPC["VPC 10.0.0.0/16"]
            subgraph Public["Public Subnets (2 AZs)"]
                ALB[NGINX Ingress / ALB]
                NAT[NAT Gateway]
            end

            subgraph Private["Private Subnets (2 AZs)"]
                subgraph EKS["EKS Cluster"]
                    subgraph NS["Namespace: ai-microservice"]
                        Pod1[App Pod 1]
                        Pod2[App Pod 2]
                        Pod3[App Pod 3]
                        PG[(PostgreSQL StatefulSet)]
                        HPA[HPA: 3-10 replicas]
                    end
                    subgraph MonNS["Namespace: monitoring"]
                        Prom[Prometheus]
                        Graf[Grafana]
                        Alert[Alertmanager]
                    end
                    subgraph LogNS["Namespace: logging"]
                        Loki[Loki + Promtail]
                    end
                end
            end
        end
        ECR[(ECR - Container Registry)]
    end

    subgraph CI["CI/CD - GitHub Actions"]
        Lint --> Test --> Build --> Scan[Trivy Scan] --> Push --> Deploy
    end

    User -->|HTTPS| ALB
    ALB --> Pod1 & Pod2 & Pod3
    Pod1 & Pod2 & Pod3 --> PG
    Prom -.scrapes /metrics.-> Pod1 & Pod2 & Pod3
    Loki -.tails logs.-> Pod1 & Pod2 & Pod3
    HPA -.scales.-> Pod1 & Pod2 & Pod3
    Deploy -->|helm upgrade| EKS
    Push --> ECR
    EKS -->|pulls image| ECR
    Private --> NAT --> Public
```

## Request flow
1. Client hits the Ingress (NGINX) over HTTPS, TLS terminated via cert-manager + Let's Encrypt.
2. Ingress routes to the `ai-microservice-svc` ClusterIP Service, load-balanced across pods.
3. Pods (non-root, resource-limited) serve FastAPI, read/write PostgreSQL via a StatefulSet with persistent volume.
4. HPA watches CPU/memory and scales pods 3→10 under load.
5. Prometheus scrapes `/metrics` on every pod every 15s; Grafana visualizes; Alertmanager fires on error-rate/restart-loop rules.
6. Promtail ships structured JSON logs to Loki, queried from the same Grafana.

## Deployment flow (CI/CD)
Push to `main` → lint → test (with ephemeral Postgres) → build Docker image →
Trivy scan (fails build on CRITICAL/HIGH CVEs) → push to ECR → `helm upgrade`
against EKS via GitHub OIDC (no static AWS keys in CI).

## Graphical Architecture Diagram

Below is the visual block diagram representing the full VPC, EKS, and CI/CD pipelines:

![Architecture Diagram](architecture.png)
