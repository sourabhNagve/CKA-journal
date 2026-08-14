#!/bin/bash
set -e

echo "Setting up Scenario 5..."

kubectl create namespace etl-jobs --dry-run=client -o yaml | kubectl apply -f -

# Create the colliding Secrets
kubectl create secret generic db-creds-primary --from-literal=USERNAME=admin --from-literal=PASSWORD=supersecret -n etl-jobs --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic db-creds-replica --from-literal=USERNAME=readonly --from-literal=PASSWORD=readsecret -n etl-jobs --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-sync
  namespace: etl-jobs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-sync
  template:
    metadata:
      labels:
        app: data-sync
    spec:
      # TRAP: Using default SA, and token is automounted
      containers:
      - name: sync-worker
        image: alpine:latest
        command: ["/bin/sh", "-c", "env && sleep 3600"]
        env:
        # TRAP: Hardcoded, insecure env vars replacing the secrets entirely
        - name: PRI_USERNAME
          value: "foo"
        - name: REP_USERNAME
          value: "bar"
EOF

echo "Scenario 5 setup complete. The deployment is insecure and failing to utilize the colliding secrets."