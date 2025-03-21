# Go Application Helm Chart

## Prerequisites

- Helm 3.x
- SOPS with GCP KMS configured
- GKE cluster
- Docker images pushed to Docker Hub

## Setup SOPS

1. Configure GCP KMS key
2. Encrypt secrets:

```bash
sops -e secrets/secrets.yaml > secrets/secrets.enc.yaml
```

```
gcloud container clusters get-credentials dev-gke-cluster \
  --region us-east1 \
  --project <project-id>
```
