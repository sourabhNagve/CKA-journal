#!/bin/bash
set -e

echo "Setting up Scenario 9..."

kubectl create namespace security --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-agent
  namespace: security
---
# Create the ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch"]
---
# TRAP: Broad ClusterRoleBinding escalating privileges globally
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-global-secret-reader
subjects:
- kind: ServiceAccount
  name: vault-agent
  namespace: security
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault-agent
  namespace: security
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vault-agent
  template:
    metadata:
      labels:
        app: vault-agent
    spec:
      serviceAccountName: vault-agent
      containers:
      - name: agent
        image: alpine/curl
        # Trap: Continuous unrestricted outbound attempts
        command: ["/bin/sh", "-c", "while true; do curl -m 2 http://google.com || true; sleep 5; done"]
EOF

echo "Scenario 9 setup complete. vault-agent has cluster-wide secret access and unrestricted Egress."