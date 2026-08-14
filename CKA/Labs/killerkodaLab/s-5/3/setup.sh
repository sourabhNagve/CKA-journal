#!/bin/bash

echo "Setting up cluster environment for Stage 3 (The Scheduling Maze)..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: pipeline-ns
EOF

# 2. Apply label to the first available node
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
echo "Labeling node $NODE_NAME with tier=frontend..."
kubectl label node "$NODE_NAME" tier=frontend --overwrite >/dev/null 2>&1

echo "Setup complete. The namespace and node labels are ready."