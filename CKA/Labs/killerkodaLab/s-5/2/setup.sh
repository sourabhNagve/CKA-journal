#!/bin/bash

echo "Setting up cluster environment for Stage 2 (The Gateway Fortress)..."

# 1. Install Gateway API CRDs (Required for the cluster to understand Gateway/HTTPRoute)
echo "Installing standard Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml >/dev/null 2>&1

echo "Waiting for CRDs to register..."
sleep 5

# 2. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: secure-vault
EOF

# 3. Create dummy GatewayClass
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: internal-gw-class
spec:
  controllerName: example.com/internal-gateway
EOF

echo "Setup complete. The 'secure-vault' namespace and Gateway API CRDs are ready."