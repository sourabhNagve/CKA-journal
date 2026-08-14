#!/bin/bash

echo "Setting up cluster environment..."

# 1. Create Namespaces
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: finance-api
  # Missing purpose=finance label intentionally
---
apiVersion: v1
kind: Namespace
metadata:
  name: finance-db
  labels:
    purpose: finance-db
---
apiVersion: v1
kind: Namespace
metadata:
  name: frontend-web
  labels:
    purpose: web
EOF

# 2. Create Database Pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: postgres-db
  namespace: finance-db
  labels:
    app: postgres
    tier: database
spec:
  containers:
  - name: postgres
    image: postgres:13-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: "secret"
    ports:
    - containerPort: 5432
EOF

# 3. Create Database Service (Intentional Typo in Selector)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: postgres-svc
  namespace: finance-db
spec:
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: postgress
EOF

# 4. Create Network Policy (Requires specific namespace label)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
  namespace: finance-db
spec:
  podSelector:
    matchLabels:
      app: postgres
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: finance
      podSelector:
        matchLabels:
          app: api-server
    ports:
    - protocol: TCP
      port: 5432
EOF

# 5. Create API Server Deployment (Stuck in Init due to DB unreachability)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: finance-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      initContainers:
      - name: wait-for-db
        image: busybox:1.32
        command: ['sh', '-c', 'until nc -z -w 2 postgres-svc.finance-db.svc.cluster.local 5432; do echo "waiting for db"; sleep 2; done;']
      containers:
      - name: api
        image: nginx:alpine
EOF

# 6. Create ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: db-troubleshooter
  namespace: finance-db
EOF

# 7. Create Noise Resources
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: dummy-config
  namespace: finance-api
data:
  api-url: "https://external.api.com"
---
apiVersion: v1
kind: Secret
metadata:
  name: dummy-secret
  namespace: finance-db
type: Opaque
data:
  token: c3VwZXJzZWNyZXQ=
EOF

echo "Setup complete. The environment is now broken and ready for the exam scenario."