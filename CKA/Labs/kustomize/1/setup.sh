#!/bin/bash
set -e

echo "Setting up Killer.sh level Kustomize CKA scenario..."

# 1. Clean up any previous runs
kubectl delete ns finance --ignore-not-found
rm -rf /opt/kustomize/billing

# 2. Create Target Namespace
kubectl create ns finance

# 3. Create Kustomize Base Directory
mkdir -p /opt/kustomize/billing/base

cat <<'EOF' > /opt/kustomize/billing/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
EOF

cat <<'EOF' > /opt/kustomize/billing/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: billing-app
  labels:
    app: billing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: billing
  template:
    metadata:
      labels:
        app: billing
    spec:
      containers:
      - name: main
        image: nginx:1.19.0
        ports:
        - containerPort: 80
        envFrom:
        - configMapRef:
            name: billing-config
EOF

cat <<'EOF' > /opt/kustomize/billing/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: billing-service
spec:
  selector:
    app: billing
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
EOF

# 4. Create Kustomize Prod Overlay Directory
mkdir -p /opt/kustomize/billing/overlays/prod

# Introduce BUG 1: Incorrect relative path to base (../base instead of ../../base)
cat <<'EOF' > /opt/kustomize/billing/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: finance

resources:
- ../base

patches:
- target:
    kind: Deployment
    name: billing-app
  path: replica-patch.yaml
EOF

# Introduce BUG 2: Incorrect JSON patch path (/spec/replica instead of /spec/replicas)
cat <<'EOF' > /opt/kustomize/billing/overlays/prod/replica-patch.yaml
- op: replace
  path: /spec/replica
  value: 3
EOF

# Missing components that candidate needs to add:
# - configMapGenerator
# - images override

cat <<'EOF' > /opt/kustomize/billing/overlays/prod/prod.env
DB_HOST=prod-db.finance.svc.cluster.local
DB_PORT=5432
LOG_LEVEL=INFO
EOF

echo "Setup complete. The Kustomize workspace is prepared at /opt/kustomize/billing."