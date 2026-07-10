# Centralized Logging

**Chosen stack: Loki + Promtail** (lighter-weight than ELK, integrates natively
with the same Grafana instance used for metrics — one pane of glass).

## Why Loki over ELK here
- Much lower resource footprint (no JVM, no Elasticsearch cluster to manage) —
  appropriate for a single small EKS cluster.
- Indexes only log labels (namespace, pod, level), not full text, so storage
  cost is a fraction of Elasticsearch for the same log volume.
- Uses the same query language style (LogQL) and lives inside Grafana
  alongside Prometheus dashboards.

**When ELK is the better choice**: high-volume, full-text search needs (fraud
detection, security forensics), or when the org already runs Elasticsearch/Kibana.

## Install
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install loki grafana/loki-stack -n logging --create-namespace \
  -f logging/loki-stack-values.yaml
```

Application logs are structured JSON (see `app/main.py` logging config) so
Loki/Promtail can parse `level`, `time`, and `msg` fields directly without
custom parsing rules.
