#!/bin/bash
set -e

echo "Setting up Scenario 7..."

# Create namespaces with specific labels
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: db-tier
  labels:
    tier: database
---
apiVersion: v1
kind: Namespace
metadata:
  name: frontend-tier
  labels:
    tier: frontend
---
apiVersion: v1
kind: Namespace
metadata:
  name: backend-tier
  labels:
    tier: backend
EOF

# Deploy StatefulSet and ServiceAccount
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: db-operator
  namespace: db-tier
---
# TRAP: Dangerous RoleBinding granting broad 'edit' access
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: db-operator-edit
  namespace: db-tier
subjects:
- kind: ServiceAccount
  name: db-operator
  namespace: db-tier
roleRef:
  kind: ClusterRole
  name: edit
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: db-tier
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  serviceName: "postgres-svc"
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: db
        image: postgres:14-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: "supersecret"
        ports:
        - containerPort: 5432
EOF

echo "Scenario 7 setup complete. The database is exposed, and the SA has dangerous permissions."