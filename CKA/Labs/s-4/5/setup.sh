#!/bin/bash

echo "Setting up control-plane environment for Lab 27 (ETCD Backup & Restore)..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (or as root). It modifies control plane components."
  exit 1
fi

ETCD_MANIFEST="/etc/kubernetes/manifests/etcd.yaml"
if [ ! -f "$ETCD_MANIFEST" ]; then
    echo "Error: $ETCD_MANIFEST does not exist. This lab requires a kubeadm control-plane node."
    exit 1
fi

if ! command -v etcdctl &> /dev/null; then
    echo "Error: etcdctl is not installed on this node. Please install etcd-client to proceed."
    exit 1
fi

# 1. Create a backup directory
mkdir -p /opt/backup

# 2. Create some dummy state in the cluster to prove data is retained
echo "Creating cluster state data..."
kubectl create configmap critical-cluster-data --from-literal=status=healthy -n default --dry-run=client -o yaml | kubectl apply -f - >/dev/null

echo "Setup complete. The cluster has some initial state, and the /opt/backup directory is ready."