#!/bin/bash

echo "Setting up cluster environment for Lab 17..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: security-audit
EOF

# 2. Create a dummy Secret to be audited
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: dummy-secret
  namespace: security-audit
type: Opaque
data:
  foo: YmFy
EOF

# 3. Create ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: auditor-sa
  namespace: security-audit
EOF

# 4. Create Role and RoleBinding
# Intentional Bug 1: RoleBinding subject has a typo ('wrong-sa-name' instead of 'auditor-sa')
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: auditor-role
  namespace: security-audit
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: auditor-binding
  namespace: security-audit
subjects:
- kind: ServiceAccount
  name: wrong-sa-name
  namespace: security-audit
roleRef:
  kind: Role
  name: auditor-role
  apiGroup: rbac.authorization.k8s.io
EOF

# 5. Create NetworkPolicy
# Intentional Bug 2: The Egress section is empty, resulting in a Default Deny for outbound traffic.
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: audit-netpol
  namespace: security-audit
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress: []
EOF

# 6. Create Deployment
# Intentional Bug 3: automountServiceAccountToken is explicitly set to false.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secret-auditor
  namespace: security-audit
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auditor
  template:
    metadata:
      labels:
        app: auditor
    spec:
      serviceAccountName: auditor-sa
      automountServiceAccountToken: false
      containers:
      - name: audit-container
        image: curlimages/curl:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          if [ ! -f /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
            echo "FAIL: No token mounted"
            sleep 5
            exit 1
          fi
          
          TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
          echo "Token found. Contacting API..."
          
          # 3 second timeout on curl to fail fast if NetPol is blocking
          HTTP_CODE=\$(curl -s -m 3 -o /dev/null -w "%{http_code}" -k -H "Authorization: Bearer \$TOKEN" https://kubernetes.default.svc/api/v1/namespaces/security-audit/secrets)
          
          if [ "\$HTTP_CODE" = "200" ]; then
            echo "SUCCESS: Secrets retrieved"
            sleep 3600
          else
            echo "FAIL: HTTP \$HTTP_CODE"
            sleep 5
            exit 1
          fi
EOF

echo "Giving the scheduler time to evaluate..."
sleep 5

echo "Setup complete. The environment is now broken and ready for the exam scenario."