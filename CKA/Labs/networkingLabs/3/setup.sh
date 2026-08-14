#!/bin/bash
set -euo pipefail

echo "Setting up Scenario 3..."

# Create the namespace
kubectl create ns finance --dry-run=client -o yaml | kubectl apply -f -

# Generate a matching TLS key and certificate
echo "Generating TLS certificate for payments.acme.corp..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/payments.key -out /tmp/payments.crt \
  -subj "/CN=payments.acme.corp" 2>/dev/null

# Create the TLS secret
kubectl create secret tls payments-tls \
  --cert=/tmp/payments.crt \
  --key=/tmp/payments.key \
  -n finance --dry-run=client -o yaml | kubectl apply -f -

# Clean up temporary cert files
rm /tmp/payments.key /tmp/payments.crt

# Deploy Workload, Service, and Ingress with intentional errors
# The 'EOF' in single quotes prevents bash from evaluating $1 as a variable
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payments-app
  namespace: finance
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payments
  template:
    metadata:
      labels:
        app: payments
    spec:
      containers:
      - name: api
        image: nginx:alpine
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: payments-svc
  namespace: finance
spec:
  type: NodePort
  selector:
    app: payments
  ports:
  - port: 80
    targetPort: 8443 # INTENTIONAL MISCONFIGURATION (Pods listen on 8080)
    # INTENTIONAL MISSING NODEPORT (Needs to be pinned to 32123)
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: payments-ingress
  namespace: finance
  annotations:
    # Wrapped in quotes to prevent YAML parsing errors with the $ symbol
    nginx.ingress.kubernetes.io/rewrite-target: "/$1" 
spec:
  # INTENTIONAL MISSING TLS BLOCK
  rules:
  - host: payments.acme.corp
    http:
      paths:
      - path: "/api/v1/pay(/|$)(.*)" # Wrapped in quotes for safe YAML regex parsing
        pathType: Prefix
        backend:
          service:
            name: payments-svc
            port:
              number: 80
EOF

echo "Scenario 3 setup complete. Good luck troubleshooting!"