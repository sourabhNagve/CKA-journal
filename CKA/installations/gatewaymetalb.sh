#!/bin/bash

set -e

echo "==> Installing Envoy Gateway (v1.8.3)..."
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.8.3 \
  -n envoy-gateway-system \
  --create-namespace

echo "==> Waiting for Envoy Gateway..."
kubectl wait --timeout=5m \
  -n envoy-gateway-system \
  deployment/envoy-gateway \
  --for=condition=Available

echo "==> Installing MetalLB (v0.16.1)..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml

echo "==> Waiting for MetalLB controller..."
kubectl wait --timeout=5m \
  -n metallb-system \
  deployment/controller \
  --for=condition=Available

kubectl wait --timeout=5m \
  -n metallb-system \
  pods \
  -l component=controller \
  --for=condition=Ready

echo "==> Creating MetalLB configuration..."
cat <<EOF > /tmp/metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
    - 172.30.1.180-172.30.1.210
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
    - first-pool
EOF

echo "==> Applying MetalLB configuration..."

for i in {1..12}; do
  if kubectl apply -f /tmp/metallb-config.yaml; then
    echo "==> MetalLB configuration applied successfully!"
    break
  fi

  if [ "$i" -eq 12 ]; then
    echo "ERROR: Failed to apply MetalLB configuration."
    rm -f /tmp/metallb-config.yaml
    exit 1
  fi

  echo "Webhook not ready. Retrying in 5 seconds... ($i/12)"
  sleep 5
done

rm -f /tmp/metallb-config.yaml

echo "==> Setup completed successfully!"
echo "==> Watching MetalLB pods (Ctrl+C to exit)..."

kubectl get pods -n metallb-system --watch