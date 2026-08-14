#!/bin/bash

echo "Setting up Killer.sh Speed Drill Round 3..."

# ==========================================
# Question 1 Setup: Storage Binding
# ==========================================
kubectl create ns storage-ns --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# Create a "decoy" PV that the PVC might accidentally bind to if not strictly configured
kubectl apply -f - <<EOF >/dev/null
apiVersion: v1
kind: PersistentVolume
metadata:
  name: decoy-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  hostPath:
    path: /mnt/decoy
EOF

# ==========================================
# Question 2 Setup: InitContainers
# ==========================================
kubectl create ns frontend-ns --dry-run=client -o yaml | kubectl apply -f - >/dev/null

# ==========================================
# Question 3 Setup: Static Pods
# ==========================================
# Ensure manifests directory exists on worker nodes (simulating standard kubeadm setup)
WORKER_NODE=$(kubectl get nodes | grep -v "control-plane" | awk 'NR>1 {print $1}' | head -n 1)
if [ -z "$WORKER_NODE" ]; then
    WORKER_NODE=$(kubectl get nodes | awk 'NR>1 {print $1}' | head -n 1)
fi
ssh -o StrictHostKeyChecking=no "$WORKER_NODE" 'sudo mkdir -p /etc/kubernetes/manifests' >/dev/null 2>&1

echo "Setup complete. Start your 18-minute timer!"