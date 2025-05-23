# Go Application Helm Chart

## NOTE: To Install all the helm charts at once, clone the repository in bastion host and run the [startup-script.sh](startup-script.sh) file from this repository.
```bash
chmod +x startup-script.sh
./startup-script.sh
```

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

## KSA and GSA setup

```
gcloud iam service-accounts add-iam-policy-binding \
  <BUCKET_SERVICE_ACCOUNT>@<PROJECT_ID>-n7.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:<PROJECT_ID>-n7.svc.id.goog[api-server/my-release-ksa]"
```

## Steps to run helm chart

1. Create namespace
   Note: First delete if there's existing namespace with same name

```bash
kubectl delete namespace api-server
```

```bash
kubectl create namespace api-server
```

2. Apply label and annotation to namespace

```bash
kubectl label namespace api-server app.kubernetes.io/managed-by=Helm
kubectl annotate namespace api-server meta.helm.sh/release-name=api-server
kubectl annotate namespace api-server meta.helm.sh/release-namespace=api-server
```

3. Add secrets to namespace

```bash
sops -d secrets/secrets.enc.yaml > templates/secrets.yaml
sops -d secrets/docker-credentials.enc.yaml > templates/docker-credentials.yaml
```

4. Install helm chart

```bash
helm install api-server . \
  --namespace api-server \
  --values values.yaml
```

5. Check the resources

```bash
kubectl get all -n api-server
```

## Note:
gcloud iam service-accounts add-iam-policy-binding \
  <GCS_SERVICE_ACCOUNT> \
  --project silicon-works-449817-n7 \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:<PROJECT_ID>.svc.id.goog[test-server-app/test-server-ksa]"

# Steps to install kafka helm chart

1. Go Inside kafka directory after cloning the repo on bastion host
```bash 
cd kafka
```

2. Run the helm dependency update command
```bash
helm dependency update
```

3. Install the kafka helm chart with release name as **pdf-upload**
```bash
helm install pdf-upload . --values values.yaml
```

1. Create a topic after installing the kafka helm chart
```bash
kubectl exec -it pdf-upload-kafka-broker-0 -n kafka -- /opt/bitnami/kafka/bin/kafka-topics.sh --create --topic pdf-upload --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

1. Check the pods in kafka namespace and if topic is created
```bash
kubectl get pods -n kafka
```
```bash
kubectl exec -it pdf-upload-kafka-broker-0 -n kafka -- /opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```


## Get gmp-system namespace pods
```kubectl get pods -n gmp-system```

## Create new topic
```kubectl exec -it pdf-upload-kafka-broker-0 -n kafka -- /opt/bitnami/kafka/bin/kafka-topics.sh --create --topic pdf-upload --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1```

## consume topic
```kubectl exec -it pdf-upload-kafka-broker-0 -n kafka -- /opt/bitnami/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic pdf-upload --from-beginning```

## List all topics
```kubectl exec -it pdf-upload-kafka-broker-0 -n kafka -- /opt/bitnami/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092```

## Add bitnami to repo
```helm repo add bitnami https://charts.bitnami.com/bitnami```
```helm repo update```

## From the kafka directory, update the chart dependencies
```helm dependency update```
