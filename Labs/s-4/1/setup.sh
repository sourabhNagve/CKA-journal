#!/bin/bash

echo "Setting up cluster environment for Lab 23 (The Stubborn Node Drain)..."

NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: upgrade-prep
EOF

# 2. Create Unmanaged Pod (Blocks drain without --force)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: legacy-job
  namespace: upgrade-prep
spec:
  containers:
  - name: busybox
    image: busybox:1.32
    command: ["/bin/sh", "-c", "sleep 3600"]
EOF

# 3. Create Deployment with emptyDir (Blocks drain without --delete-emptydir-data)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: local-cache
  namespace: upgrade-prep
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
      - name: redis
        image: redis:alpine
        volumeMounts:
        - name: cache-vol
          mountPath: /data
      volumes:
      - name: cache-vol
        emptyDir: {}
EOF

# 4. Create DaemonSet (Blocks drain without --ignore-daemonsets)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
  namespace: upgrade-prep
spec:
  selector:
    matchLabels:
      app: monitor
  template:
    metadata:
      labels:
        app: monitor
    spec:
      tolerations:
      - operator: "Exists" # Ensure it runs everywhere
      containers:
      - name: agent
        image: nginx:alpine
EOF

# 5. Create Deployment and Strict PDB (Hangs drain completely)
# MinAvailable is 2, and Replicas is 2. The API server will reject any eviction request.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ha-app
  namespace: upgrade-prep
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ha
  template:
    metadata:
      labels:
        app: ha
    spec:
      containers:
      - name: web
        image: nginx:alpine
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ha-app-pdb
  namespace: upgrade-prep
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: ha
EOF

echo "Waiting for workloads to schedule on node: $NODE_NAME..."
sleep 15

echo "Setup complete. Try to 'kubectl drain $NODE_NAME' and fix the errors that appear."