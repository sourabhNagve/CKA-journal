#!/bin/bash
set -e

echo "Setting up Scenario 1..."

kubectl create namespace finance-system --dry-run=client -o yaml | kubectl apply -f -

# Create Revision 1 (Working state, but bad scheduling)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: finance-api
  namespace: finance-system
  annotations:
    kubernetes.io/change-cause: "Initial stable release"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: finance-api
  template:
    metadata:
      labels:
        app: finance-api
    spec:
      containers:
      - name: api
        image: nginx:1.24-alpine
        ports:
        - containerPort: 80
EOF

# Wait for rollout
kubectl rollout status deployment/finance-api -n finance-system --timeout=30s > /dev/null 2>&1 || true

# Apply Revision 2 (Botched state)
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: finance-api
  namespace: finance-system
  annotations:
    kubernetes.io/change-cause: "Botched security update"
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 50%
      maxSurge: 1
  selector:
    matchLabels:
      app: finance-api
  template:
    metadata:
      labels:
        app: finance-api
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: tier
                operator: In
                values:
                - does-not-exist
      containers:
      - name: api
        image: nginx:1.24-alpine
        command: ["/bin/sh", "-c", "exit 1"] # Crashloop trap
        resources:
          requests:
            cpu: 2
            memory: 4Gi # Intentional resource trap
EOF

echo "Scenario 1 setup complete. The deployment is currently failing and stuck."