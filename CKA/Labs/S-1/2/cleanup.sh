#!/bin/bash

echo "Cleaning up cluster environment..."

# 1. Remove node taints
echo "Removing taints from nodes..."
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  kubectl taint node "$node" tier=cache:NoSchedule- 2>/dev/null || true
done

# 2. Delete Namespace (Cascades to STS, Pods, PVCs)
echo "Deleting namespace..."
kubectl delete ns data-ops --ignore-not-found=true

# Wait for namespace deletion
while kubectl get ns data-ops 2>/dev/null | grep -q "Terminating"; do
  sleep 2
done

# 3. Delete PVs and StorageClass
echo "Deleting PVs and StorageClass..."
kubectl delete pv pv-cache-0 pv-cache-1 --ignore-not-found=true
kubectl delete sc nvme-sc --ignore-not-found=true

echo "Cleanup complete."