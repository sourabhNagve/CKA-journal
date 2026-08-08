#!/bin/bash
set -e

echo "Setting up Killer.sh level Helm scenario..."

# 1. Clean up any previous runs
helm uninstall dash-frontend -n monitoring 2>/dev/null || true
kubectl delete ns monitoring 2>/dev/null || true
rm -rf /opt/charts/dash-frontend /opt/charts/redis-cache /tmp/dash-frontend-v1

# 2. Create Target Namespace
kubectl create ns monitoring

# 3. Create v1 Chart (Working baseline)
mkdir -p /tmp/dash-frontend-v1/templates
cat <<'EOF' > /tmp/dash-frontend-v1/Chart.yaml
apiVersion: v2
name: dash-frontend
version: 1.0.0
EOF
cat <<'EOF' > /tmp/dash-frontend-v1/templates/deployment.yaml
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
      - name: frontend
        image: nginx:1.24-alpine
EOF

# Install v1
helm install dash-frontend /tmp/dash-frontend-v1 -n monitoring
rm -rf /tmp/dash-frontend-v1

# 4. Create the unmanaged ConfigMap (This will cause the Helm adoption conflict)
kubectl create configmap dash-frontend-config --from-literal=theme=dark --from-literal=refresh_interval=30 -n monitoring

# 5. Create the local dependency chart
mkdir -p /opt/charts/redis-cache/templates
cat <<'EOF' > /opt/charts/redis-cache/Chart.yaml
apiVersion: v2
name: redis-cache
version: 1.0.0
EOF
cat <<'EOF' > /opt/charts/redis-cache/templates/pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ .Release.Name }}-redis
  namespace: {{ .Release.Namespace }}
  labels:
    app: redis-cache
spec:
  containers:
  - name: redis
    image: redis:7-alpine
EOF

# 6. Prepare v2 Target Chart with bugs and dependencies
mkdir -p /opt/charts/dash-frontend/templates
cat <<'EOF' > /opt/charts/dash-frontend/Chart.yaml
apiVersion: v2
name: dash-frontend
version: 2.0.0
dependencies:
- name: redis-cache
  version: 1.0.0
  repository: file://../redis-cache
EOF

cat <<'EOF' > /opt/charts/dash-frontend/values.yaml
backend:
  # BUG: This will be interpreted as an int, but k8s env values MUST be strings
  port: 8080 
EOF

# Note: We intentionally DO NOT generate the ConfigMap template here because 
# the user is supposed to adopt the existing one. Wait, to adopt a resource, 
# Helm MUST have it in the templates. Let's add the template so it conflicts.
cat <<'EOF' > /opt/charts/dash-frontend/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: dash-frontend-config
  namespace: {{ .Release.Namespace }}
data:
  theme: dark
  refresh_interval: "30"
EOF

cat <<'EOF' > /opt/charts/dash-frontend/templates/deployment.yaml
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
      - name: frontend
        image: nginx:1.25-alpine
        env:
        - name: BACKEND_PORT
          value: {{ .Values.backend.port }} # BUG: Lacks | quote, causes type error
EOF

echo "Setup complete. The 'dash-frontend' release is at v1. The v2 chart at /opt/charts/dash-frontend is ready for troubleshooting."