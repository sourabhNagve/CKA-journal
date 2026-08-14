#!/bin/bash
set -e

echo "Setting up Killer.sh level Helm CKA scenario..."

# 1. Clean up any previous runs
helm uninstall log-processor -n logging 2>/dev/null || true
kubectl delete ns logging 2>/dev/null || true
rm -rf /opt/charts/log-processor

# 2. Create Target Namespace
kubectl create ns logging

# 3. Prepare local Chart directory
mkdir -p /opt/charts/log-processor/templates

cat <<'EOF' > /opt/charts/log-processor/Chart.yaml
apiVersion: v2
name: log-processor
description: A Helm chart for Log Processor
type: application
version: 1.1.0
appVersion: "1.0.0"
EOF

cat <<'EOF' > /opt/charts/log-processor/values.yaml
replicaCount: 1
image:
  repository: alpine
  tag: "3.18"
  pullPolicy: IfNotPresent
EOF

cat <<'EOF' > /opt/charts/log-processor/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
  namespace: {{ .Release.Namespace }}
data:
  app.conf: |
    log_level=debug
    output=/var/log/app.log
EOF

# Write the INITIAL statefulset (Correct selector, WRONG mount)
cat <<'EOF' > /opt/charts/log-processor/templates/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  serviceName: {{ .Release.Name }}
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: log-processor
  template:
    metadata:
      labels:
        app: log-processor
    spec:
      containers:
      - name: processor
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        command: ["/bin/sh", "-c", "cat /etc/config/app.conf && sleep 3600"]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/log-config  # BUG: Should be /etc/config
      volumes:
      - name: config-volume
        configMap:
          name: {{ .Release.Name }}-config
EOF

# 4. Install Initial Revision (Pod will crashloop because mount is wrong)
helm install log-processor /opt/charts/log-processor -n logging

# 5. Overwrite the statefulset chart file to introduce the IMMUTABLE FIELD bug for the user
cat <<'EOF' > /opt/charts/log-processor/templates/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  serviceName: {{ .Release.Name }}
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: custom-logger # BUG: Immutable field changed! Will block helm upgrade.
  template:
    metadata:
      labels:
        app: custom-logger
    spec:
      containers:
      - name: processor
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        command: ["/bin/sh", "-c", "cat /etc/config/app.conf && sleep 3600"]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/log-config  # BUG: Still wrong, user must fix.
      volumes:
      - name: config-volume
        configMap:
          name: {{ .Release.Name }}-config
EOF

# Wait briefly to let the pod enter a failing state
sleep 5

echo "Setup complete. The 'log-processor' application is crash-looping, and the local chart is poisoned."