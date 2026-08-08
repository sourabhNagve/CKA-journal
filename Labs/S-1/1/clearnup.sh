#!/bin/bash

echo "Cleaning up cluster environment..."

# Delete Namespaces (this cascades to deployments, pods, services, network policies, etc.)
kubectl delete ns finance-api finance-db frontend-web --ignore-not-found=true

# Wait for namespaces to terminate to ensure clean state
echo "Waiting for namespaces to be fully removed..."
while kubectl get ns finance-api finance-db frontend-web 2>/dev/null | grep -q "Terminating"; do
  sleep 2
done

echo "Cleanup complete."