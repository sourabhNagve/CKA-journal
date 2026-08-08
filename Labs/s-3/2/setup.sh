#!/bin/bash

echo "Setting up node-level environment for Lab 16 (etcd Disaster Recovery)..."

# Ensure the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (or as root). It interacts with node-level files."
  exit 1
fi

# Ensure we are on a kubeadm control-plane node
if [ ! -d "/etc/kubernetes/manifests" ]; then
    echo "Error: /etc/kubernetes/manifests does not exist. Must run on a kubeadm control-plane node."
    exit 1
fi

# 1. Create the critical resources
echo "Creating critical-data namespace and workloads..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: critical-data
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-backend
  namespace: critical-data
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
EOF

echo "Waiting for workload to be ready..."
kubectl wait --for=condition=Available deploy/db-backend -n critical-data --timeout=60s

# 2. Take the etcd snapshot
echo "Taking etcd snapshot..."
mkdir -p /opt/backup

ETCD_POD=$(kubectl get pods -n kube-system -l component=etcd -o jsonpath='{.items[0].metadata.name}')

if [ -z "$ETCD_POD" ]; then
  echo "Error: Could not find etcd pod."
  exit 1
fi

# Use the etcd pod to run etcdctl, which avoids needing etcdctl installed on the host
 ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/backup/etcd-snapshot.db



# Backup the original etcd.yaml to make cleanup easy later
cp /etc/kubernetes/manifests/etcd.yaml /opt/backup/etcd.yaml.orig

# 3. Simulate the disaster
echo "Simulating disaster by deleting the critical-data namespace..."
kubectl delete ns critical-data

# Wait for deletion to complete
while kubectl get ns critical-data 2>/dev/null | grep -q "Terminating"; do
  sleep 2
done

echo "Setup complete. The cluster is healthy, but critical data is missing. The backup is at /opt/backup/etcd-snapshot.db"