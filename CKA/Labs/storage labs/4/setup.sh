#!/bin/bash
set -e

echo "Setting up Scenario 4..."

kubectl create namespace redis-cluster --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache-node
  namespace: redis-cluster
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cache-node
  template:
    metadata:
      labels:
        app: cache-node
    spec:
      containers:
      - name: cache
        image: redis:6.2-alpine
        # TRAP: No ephemeral-storage constraints, no lifecycle hooks
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
      # TRAP: PodAntiAffinity by hostname instead of Zonal TopologySpreadConstraint
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: cache-node
              topologyKey: kubernetes.io/hostname
EOF

echo "Scenario 4 setup complete. cache-node is vulnerable to eviction, abrupt termination, and zonal failure."