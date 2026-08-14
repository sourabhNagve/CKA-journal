#!/bin/bash

echo "Setting up cluster environment for Stage 1 (The Autoscaling Trap)..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: accounting
EOF

# 2. Create ConfigMap and Secret
kubectl create configmap app-config --from-literal=mode=production -n accounting
kubectl create secret generic db-credentials --from-literal=DB_USER=admin --from-literal=DB_PASS=supersecret -n accounting

# 3. Create initial "Stable" Deployment (Revision 1)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: finance-api
  namespace: accounting
spec:
  replicas: 1
  selector:
    matchLabels:
      app: finance
  template:
    metadata:
      labels:
        app: finance
    spec:
      containers:
      - name: api
        image: nginx:1.21-alpine # Stable image
        command: ["/bin/sh", "-c", "sleep 3600"]
EOF

echo "Waiting for Revision 1 to stabilize..."
sleep 5

# 4. Trigger a bad update (Revision 2 - CrashLoopBackOff)
kubectl set image deployment/finance-api api=nginx:invalid-image-tag -n accounting

# 5. Create the HPA (Will fail because pod has no resource limits)
kubectl autoscale deployment finance-api --cpu-percent=50 --min=2 --max=5 -n accounting

# 6. Ensure metrics-server is running (Simulated for this lab environment if not present)
if ! kubectl get pods -n kube-system | grep -q metrics-server; then
  echo "Warning: metrics-server not found. In a real exam, this is required for HPA."
fi

mkdir -p /opt

echo "Setup complete. The rollout is failing, and the HPA is broken."