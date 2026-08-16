#!/bin/bash
set -e

echo "Setting up Killer.sh level Helm scenario..."

# 1. Cleanup previous runs
helm uninstall web-store -n e-commerce 2>/dev/null || true
kubectl delete ns e-commerce 2>/dev/null || true
rm -rf /opt/charts/web-store /tmp/web-store-v1

# 2. Create Target Namespace
kubectl create ns e-commerce

# 3. Create v1 Chart (Working baseline)
mkdir -p /tmp/web-store-v1/templates
cat <<'EOF' > /tmp/web-store-v1/Chart.yaml
apiVersion: v2
name: web-store
version: 1.0.0
EOF

cat <<'EOF' > /tmp/web-store-v1/values.yaml
storage:
  size: 2Gi
migration:
  image: busybox:1.36.1
EOF

cat <<'EOF' > /tmp/web-store-v1/templates/hook-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-db-migration
  namespace: {{ .Release.Namespace }}
  annotations:
    "helm.sh/hook": pre-upgrade
spec:
  backoffLimit: 1
  template:
    spec:
      containers:
      - name: migrate
        image: {{ .Values.migration.image }}
        command: ["sh", "-c", "echo 'Migrating DB...'; sleep 2"]
      restartPolicy: Never
EOF

cat <<'EOF' > /tmp/web-store-v1/templates/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  serviceName: {{ .Release.Name }}
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
      - name: app
        image: nginx:alpine
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: {{ .Values.storage.size }}
EOF

# 4. Install Initial Revision (v1)
helm install web-store /tmp/web-store-v1 -n e-commerce
kubectl rollout status sts/web-store -n e-commerce --timeout=45s

# 5. Prepare v2 Chart at target directory with bugs
mkdir -p /opt/charts/web-store/templates
cp /tmp/web-store-v1/templates/* /opt/charts/web-store/templates/

cat <<'EOF' > /opt/charts/web-store/Chart.yaml
apiVersion: v2
name: web-store
version: 2.0.0
EOF

cat <<'EOF' > /opt/charts/web-store/values.yaml
storage:
  size: 5Gi  # BUG 1: StatefulSet storage is immutable, must be reverted to 2Gi
migration:
  image: busybox:invalid-tag # BUG 2: Invalid image prevents hook from completing
EOF

# 6. Force a failed upgrade to poison the release state
echo "Simulating a failed upgrade (this will take 15 seconds)..."
helm upgrade web-store /opt/charts/web-store -n e-commerce --wait --timeout 15s 2>/dev/null || true

# Cleanup temp files
rm -rf /tmp/web-store-v1

echo "Setup complete. The 'web-store' release is currently in a 'failed' state and requires troubleshooting."