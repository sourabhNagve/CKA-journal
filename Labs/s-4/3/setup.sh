#!/bin/bash

echo "Setting up cluster environment for Lab 25 (Sidecar Logging)..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: logging-ns
EOF

# 2. Create the legacy deployment (Writes to file, no stdout)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-app
  namespace: logging-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: legacy
  template:
    metadata:
      labels:
        app: legacy
    spec:
      containers:
      - name: app-container
        image: busybox:1.32
        command: ["/bin/sh", "-c"]
        args:
        - |
          mkdir -p /var/log/legacy
          counter=1
          while true; do
            echo "[INFO] Application processing transaction \$counter..." >> /var/log/legacy/app.log
            counter=\$((counter+1))
            sleep 2
          done
EOF

echo "Waiting for legacy-app to deploy..."
sleep 10

echo "Setup complete. Run 'kubectl logs deploy/legacy-app -n logging-ns' and notice that it is completely empty."