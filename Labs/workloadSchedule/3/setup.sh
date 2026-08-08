#!/bin/bash
set -e

echo "Setting up Scenario 3..."

kubectl create namespace data-pipeline --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-processor
  namespace: data-pipeline
spec:
  replicas: 1
  selector:
    matchLabels:
      app: data-processor
  template:
    metadata:
      labels:
        app: data-processor
    spec:
      containers:
      - name: worker
        image: busybox
        command: ["/bin/sh", "-c", "while true; do sleep 3600; done"]
        # TRAP: No resources defined, HPA will show <unknown>/X%
        env:
        # TRAP: Hardcoded colliding variables
        - name: LOG_LEVEL
          value: "INFO"
        - name: BATCH_SIZE
          value: "10"
EOF

echo "Scenario 3 setup complete. The deployment lacks resources and is using hardcoded legacy env vars."