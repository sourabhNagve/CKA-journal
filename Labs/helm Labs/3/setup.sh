#!/bin/bash
set -e

echo "Setting up Killer.sh level Helm CKA scenario..."

# 1. Clean up any previous runs
helm uninstall data-pipeline -n etl-prod 2>/dev/null || true
kubectl delete ns etl-prod 2>/dev/null || true
rm -rf /opt/charts/data-pipeline /tmp/data-pipeline-v1

# 2. Create Target Namespace
kubectl create ns etl-prod

# 3. Create Redis Dependency
kubectl run data-pipeline-redis --image=redis:7-alpine --labels="app=redis" --namespace=etl-prod --expose --port=6379

# 4. Create Default Deny Egress NetworkPolicy
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: etl-prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
EOF

# 5. Prepare v1 Chart (Working, no init containers, no NP)
mkdir -p /tmp/data-pipeline-v1/templates
cat <<'EOF' > /tmp/data-pipeline-v1/Chart.yaml
apiVersion: v2
name: data-pipeline
version: 1.0.0
EOF
cat <<'EOF' > /tmp/data-pipeline-v1/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: main
        image: nginx:1.24-alpine
EOF

# Install v1
helm install data-pipeline /tmp/data-pipeline-v1 -n etl-prod

# 6. Create the unmanaged Secret (This will cause the Helm adoption conflict)
kubectl create secret generic api-token --from-literal=token=supersecret123 -n etl-prod

# 7. Prepare v2 Chart at the target directory (Contains bugs)
mkdir -p /opt/charts/data-pipeline/templates
cat <<'EOF' > /opt/charts/data-pipeline/Chart.yaml
apiVersion: v2
name: data-pipeline
description: Data Pipeline v2 with Redis Egress
version: 2.0.0
EOF

cat <<'EOF' > /opt/charts/data-pipeline/templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-token
  namespace: {{ .Release.Namespace }}
type: Opaque
data:
  token: c3VwZXJzZWNyZXQxMjM= # supersecret123
EOF

cat <<'EOF' > /opt/charts/data-pipeline/templates/networkpolicy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ .Release.Name }}-allow-redis
  namespace: {{ .Release.Namespace }}
spec:
  podSelector:
    matchLabels:
      app: wrong-app-name # BUG: This should be {{ .Release.Name }}
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379
EOF

cat <<'EOF' > /opt/charts/data-pipeline/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      initContainers:
      - name: check-redis
        image: alpine:3.18
        command:
        - sh
        - -c
        - |
          for i in $(seq 1 3); do
            nc -z -w 2 data-pipeline-redis 6379 && exit 0
            echo "Waiting for Redis..."
            sleep 2
          done
          exit 1
      containers:
      - name: main
        image: nginx:1.24-alpine
        env:
        - name: API_TOKEN
          valueFrom:
            secretKeyRef:
              name: api-token
              key: token
EOF

# Clean up temp v1 chart
rm -rf /tmp/data-pipeline-v1

echo "Setup complete. The 'data-pipeline' release is at v1. The v2 chart at /opt/charts/data-pipeline is ready for the candidate to troubleshoot."