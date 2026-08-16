#!/bin/bash
set -euo pipefail

echo "Setting up Scenario 2..."

# Create namespaces
kubectl create ns sec-front --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns sec-back --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns sec-db --dry-run=client -o yaml | kubectl apply -f -
kubectl create ns ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

# Deploy dummy workloads
kubectl run frontend --image=nginx:alpine -n sec-front --labels="app=frontend"
kubectl run backend --image=nginx:alpine -n sec-back --labels="app=backend"
kubectl run database --image=postgres:alpine -n sec-db --labels="app=database"

# Apply strictly broken / incomplete Network Policies
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: sec-front
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: sec-back
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: sec-db
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

echo "Scenario 2 setup complete."



















