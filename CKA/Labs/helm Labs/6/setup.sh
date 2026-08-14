### setup.sh
#!/bin/bash
set -e

echo "Setting up the CKA Helm scenario..."

# 1. Cleanup any previous runs
helm uninstall payment-gateway -n payments 2>/dev/null || true
kubectl delete namespace payments 2>/dev/null || true
rm -rf /opt/helm-charts/payment-gateway

# 2. Create Namespace and static resources
kubectl create namespace payments

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: payments
type: Opaque
data:
  password: c3VwZXJzZWNyZXQ= # supersecret
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-payments
  namespace: payments
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-restricted-internal
  namespace: payments
spec:
  podSelector:
    matchLabels:
      security-tier: restricted
  ingress:
  - from:
    - namespaceSelector: {}
EOF

# 3. Create the local Helm Chart
mkdir -p /opt/helm-charts/payment-gateway/templates

cat <<EOF > /opt/helm-charts/payment-gateway/Chart.yaml
apiVersion: v2
name: payment-gateway
description: A Helm chart for the payment gateway
type: application
version: 1.1.0
appVersion: "1.0.0"
EOF

cat <<EOF > /opt/helm-charts/payment-gateway/values.yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.999.0"
  pullPolicy: IfNotPresent

labels:
  security-tier: "public"

rbac:
  enabled: true
  secretAccess: false
EOF

cat <<EOF > /opt/helm-charts/payment-gateway/templates/serviceaccount.yaml
{{- if .Values.rbac.enabled }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ .Release.Name }}-sa
  namespace: {{ .Release.Namespace }}
{{- end }}
EOF

cat <<EOF > /opt/helm-charts/payment-gateway/templates/role.yaml
{{- if .Values.rbac.enabled }}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ .Release.Name }}-role
  namespace: {{ .Release.Namespace }}
rules:
{{- if .Values.rbac.secretAccess }}
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
{{- else }}
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
{{- end }}
{{- end }}
EOF

cat <<EOF > /opt/helm-charts/payment-gateway/templates/rolebinding.yaml
{{- if .Values.rbac.enabled }}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ .Release.Name }}-rolebinding
  namespace: {{ .Release.Namespace }}
subjects:
- kind: ServiceAccount
  name: {{ .Release.Name }}-sa
  namespace: {{ .Release.Namespace }}
roleRef:
  kind: Role
  name: {{ .Release.Name }}-role
  apiGroup: rbac.authorization.k8s.io
{{- end }}
EOF

cat <<EOF > /opt/helm-charts/payment-gateway/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app: {{ .Release.Name }}
{{- if .Values.labels }}
{{ toYaml .Values.labels | indent 4 }}
{{- end }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
{{- if .Values.labels }}
{{ toYaml .Values.labels | indent 8 }}
{{- end }}
    spec:
      serviceAccountName: {{ .Release.Name }}-sa
      initContainers:
      - name: check-secret
        image: bitnami/kubectl:latest
        command: ['kubectl', 'get', 'secret', 'db-credentials']
      containers:
      - name: gateway
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: 80
EOF

# 4. Install the broken Helm release
helm install payment-gateway /opt/helm-charts/payment-gateway -n payments

echo "Setup complete. The 'payment-gateway' release is currently degraded."