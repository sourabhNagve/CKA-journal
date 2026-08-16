#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "==> Installing ingresscontroller..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
kubectl create namespace traefik

helm install traefik traefik/traefik --namespace traefik

echo "==> Waiting for gateway deployment to become Available..."

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml

echo "==> Waiting for MetalLB controller to become Available..."
kubectl wait --timeout=5m -n metallb-system deployment/controller --for=condition=Available
kubectl wait --timeout=5m -n metallb-system pods -l component=controller --for=condition=Ready

echo "==> Creating MetalLB configuration file..."
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

echo "==> Applying MetalLB configuration (waiting for webhook to be ready)..."
# Temporarily disable exit-on-error for the retry loop
set +e 

# Retry up to 12 times (approx 1 minute)
for i in {1..12}; do
  kubectl apply -f /tmp/metallb-config.yaml
  if [ $? -eq 0 ]; then
    echo "==> MetalLB configuration applied successfully!"
    break
  fi
  echo "Webhook not ready yet. Retrying in 5 seconds... ($i/12)"
  sleep 5
done

# Re-enable exit-on-error
set -e
rm /tmp/metallb-config.yaml

echo "==> Setup completed successfully!"

echo "==> Watching MetalLB pods (Press Ctrl+C to exit)..."
kubectl get pods -n metallb-system --watch