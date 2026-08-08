#!/bin/bash

echo "Setting up cluster environment for Lab 28 (NetworkPolicies & Isolation)..."

# 1. Create Namespaces and label the database namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: secure-app
---
apiVersion: v1
kind: Namespace
metadata:
  name: database-ns
  labels:
    name: database-ns
EOF

# 2. Deploy Database Pod
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  namespace: database-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: redis
        image: redis:alpine
        command: ["/bin/sh", "-c", "nc -lk -p 5432"] # Simple TCP listener on 5432
---
apiVersion: v1
kind: Service
metadata:
  name: db-svc
  namespace: database-ns
spec:
  ports:
  - port: 5432
    targetPort: 5432
  selector:
    app: db
EOF

# 3. Deploy Frontend and Backend in secure-app
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: secure-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: web
        image: busybox:1.32
        command: ["/bin/sh", "-c", "sleep 3600"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: secure-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: app
        image: busybox:1.32
        command: ["/bin/sh", "-c", "nc -lk -p 8080 & sleep 3600"]
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: secure-app
spec:
  ports:
  - port: 8080
    targetPort: 8080
  selector:
    app: backend
EOF

# 4. Apply Default Deny Policy
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: secure-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# 5. Apply Broken Policy
# BUG 1: Missing Egress policyType declaration
# BUG 2: OR logic instead of AND logic for cross-namespace database egress
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-traffic
  namespace: secure-app
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress # BUG: Missing 'Egress' in policyTypes!
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:      # BUG: Written as two array elements (OR) instead of combined (AND)
        matchLabels:
          app: db
    - namespaceSelector:
        matchLabels:
          name: database-ns
    ports:
    - protocol: TCP
      port: 5432
EOF

echo "Waiting for workloads to schedule..."
sleep 10

echo "Setup complete. Network policies applied. Traffic is currently blocked."