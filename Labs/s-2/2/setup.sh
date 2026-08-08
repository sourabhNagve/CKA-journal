#!/bin/bash

echo "Setting up cluster environment for Lab 13..."

# 1. Create Namespaces
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: security-tools
---
apiVersion: v1
kind: Namespace
metadata:
  name: app-prod
  labels:
    shield: enabled
EOF

# 2. Create the Secret with specific keys (cert.pem, key.pem)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: gateway-certs
  namespace: app-prod
type: Opaque
data:
  cert.pem: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCg==
  key.pem: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCg==
EOF

# 3. Create a broken ValidatingWebhookConfiguration
# Intentional Bug 1: Points to a service that doesn't exist, with failurePolicy: Fail.
# This prevents ANY pod creation in namespaces labeled shield: enabled.
kubectl apply -f - <<EOF
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: shield-webhook.acme.com
webhooks:
  - name: validate.shield.acme.com
    rules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        operations: ["CREATE"]
        resources: ["pods"]
    failurePolicy: Fail
    sideEffects: None
    admissionReviewVersions: ["v1", "v1beta1"]
    clientConfig:
      service:
        namespace: security-tools
        name: shield-svc
        path: /validate
      caBundle: "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCg=="
    namespaceSelector:
      matchLabels:
        shield: enabled
EOF

# 4. Create the Deployment
# Intentional Bug 2: Requires 'gateway-sa' which doesn't exist.
# Intentional Bug 3: Typo in secretName ('gateway-cert' instead of 'gateway-certs').
# Intentional Bug 4: Expects 'tls.crt' but secret keys are 'cert.pem' (requires 'items' mapping).
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-gateway
  namespace: app-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment
  template:
    metadata:
      labels:
        app: payment
    spec:
      serviceAccountName: gateway-sa
      containers:
      - name: gateway
        image: busybox:1.32
        command: ["/bin/sh", "-c"]
        args:
        - |
          if [ -f "/certs/tls.crt" ]; then
            echo "Cert found, starting..."
            sleep 3600
          else
            echo "Error: /certs/tls.crt not found!"
            exit 1
          fi
        volumeMounts:
        - name: cert-vol
          mountPath: /certs
      volumes:
      - name: cert-vol
        secret:
          secretName: gateway-cert
EOF

echo "Giving the ReplicaSet time to fail against the webhook..."
sleep 5

echo "Setup complete. The environment is now broken and ready for the exam scenario."