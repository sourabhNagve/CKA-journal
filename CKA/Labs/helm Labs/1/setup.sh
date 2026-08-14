#!/bin/bash
set -e

echo "Setting up Killer.sh level Helm CKA scenario..."

# 1. Clean up any previous runs
helm uninstall app-vault -n prod-apps 2>/dev/null || true
kubectl delete ns prod-apps 2>/dev/null || true
rm -rf /opt/charts/app-vault /tmp/production-values.yaml

# 2. Create Target Namespace
kubectl create ns prod-apps

# 3. Create existing ConfigMap
kubectl apply -n prod-apps -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-config
  namespace: prod-apps
data:
  schema_version: "1.0"
EOF

# 4. Prepare local Chart directory
mkdir -p /opt/charts/app-vault/templates

cat <<'EOF' > /opt/charts/app-vault/Chart.yaml
apiVersion: v2
name: app-vault
description: Production Vault Application Chart
type: application
version: 2.4.0
appVersion: "2.4.0"
EOF

cat <<'EOF' > /opt/charts/app-vault/values.yaml
replicaCount: 1
image:
  repository: nginx
  tag: "1.25.3-alpine"
  pullPolicy: IfNotPresent

migration:
  enabled: true
EOF

cat <<'EOF' > /tmp/production-values.yaml
replicaCount: 2
image:
  tag: "1.25.4-alpine"
migration:
  enabled: true
EOF

cat <<'EOF' > /opt/charts/app-vault/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-vault-hook-sa
  namespace: {{ .Release.Namespace }}
EOF

cat <<'EOF' > /opt/charts/app-vault/templates/role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-vault-hook-role
  namespace: {{ .Release.Namespace }}
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"] # Missing 'patch' / 'update' required by migration hook
EOF

cat <<'EOF' > /opt/charts/app-vault/templates/rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-vault-hook-rb
  namespace: {{ .Release.Namespace }}
subjects:
- kind: ServiceAccount
  name: app-vault-hook-sa
  namespace: {{ .Release.Namespace }}
roleRef:
  kind: Role
  name: app-vault-hook-role
  apiGroup: rbac.authorization.k8s.io
EOF

cat <<'EOF' > /opt/charts/app-vault/templates/hook-job.yaml
{{- if .Values.migration.enabled }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Release.Name }}-db-migrate
  namespace: {{ .Release.Namespace }}
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-delete-policy": hook-failed,before-hook-creation
spec:
  backoffLimit: 1
  template:
    spec:
      serviceAccountName: app-vault-hook-sa
      restartPolicy: Never
      containers:
      - name: migrate
        image: bitnami/kubectl:latest
        command:
        - /bin/sh
        - -c
        - |
          echo "Checking db-config..."
          kubectl get configmap db-config -n {{ .Release.Namespace }} || exit 1
          echo "Updating schema..."
          kubectl patch configmap db-config -n {{ .Release.Namespace }} --type merge -p '{"data":{"schema_version":"2.0"}}'
{{- end }}
EOF

cat <<'EOF' > /opt/charts/app-vault/templates/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ .Release.Name }}-backend
  namespace: {{ .Release.Namespace }}
spec:
  serviceName: {{ .Release.Name }}
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: vault
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: 80
EOF

# 5. Install Initial Revision (v2.3.0)
sed -i 's/version: 2.4.0/version: 2.3.0/' /opt/charts/app-vault/Chart.yaml
helm install app-vault /opt/charts/app-vault -n prod-apps --set migration.enabled=false
sed -i 's/version: 2.3.0/version: 2.4.0/' /opt/charts/app-vault/Chart.yaml

# 6. Force release into stuck pending-upgrade state
helm upgrade app-vault /opt/charts/app-vault -n prod-apps -f /tmp/production-values.yaml --timeout 2s --wait 2>/dev/null || true

SECRET_NAME=$(kubectl get secret -n prod-apps -l owner=helm,name=app-vault -o jsonpath='{.items[-1].metadata.name}' 2>/dev/null || true)
if [ -n "$SECRET_NAME" ]; then
  DATA=$(kubectl get secret "$SECRET_NAME" -n prod-apps -o jsonpath='{.data.release}')
  NEW_DATA=$(echo "$DATA" | base64 -d | base64 -d | gzip -d | sed 's/"status":"[^"]*"/"status":"pending-upgrade"/' | gzip | base64 | base64 -w0)
  kubectl patch secret "$SECRET_NAME" -n prod-apps --type json -p="[{\"op\": \"replace\", \"path\": \"/data/release\", \"value\": \"$NEW_DATA\"}]"
fi

echo "Setup complete. Helm release 'app-vault' in namespace 'prod-apps' is stuck in 'pending-upgrade'."