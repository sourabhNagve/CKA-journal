#!/bin/bash

echo "Setting up cluster environment for Lab 29 (The Final Boss)..."

NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# 1. Break CoreDNS
echo "Injecting syntax error into CoreDNS ConfigMap..."
kubectl get cm coredns -n kube-system -o yaml > /tmp/coredns-backup.yaml
# Add a rogue configuration line into the Corefile
kubectl get cm coredns -n kube-system -o yaml | sed 's/loop/loop\n    syntax_error_do_not_load/g' | kubectl apply -f - >/dev/null 2>&1
# Kill current CoreDNS pods to force them to read the broken config and crash
kubectl delete pods -n kube-system -l k8s-app=kube-dns >/dev/null 2>&1

# 2. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: processing
EOF

# 3. Taint the Node (Blocks scheduling)
echo "Applying maintenance taint to node $NODE_NAME..."
kubectl taint nodes "$NODE_NAME" maintenance=active:NoSchedule --overwrite >/dev/null 2>&1

# 4. Create PV and Mismatched PVC
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: data-pv
spec:
  capacity:
    storage: 2Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data-boss
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: processing
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi  # BUG: Requests 5Gi, PV only has 2Gi
  storageClassName: standard
EOF

# 5. Create Redis backend and broken Service
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
  namespace: processing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-backend
  template:
    metadata:
      labels:
        app: redis-backend
    spec:
      tolerations:
      - key: "maintenance"
        operator: "Equal"
        value: "active"
        effect: "NoSchedule"
      containers:
      - name: redis
        image: redis:alpine
---
apiVersion: v1
kind: Service
metadata:
  name: redis-queue
  namespace: processing
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: rediss-backend # BUG: Typo in selector (rediss instead of redis)
EOF

# 6. Create the Data Processor Application
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-processor
  namespace: processing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: processor
  template:
    metadata:
      labels:
        app: processor
      # BUG: Missing toleration for maintenance=active:NoSchedule
    spec:
      containers:
      - name: app
        image: busybox:1.32
        command: ["/bin/sh", "-c"]
        args:
        - |
          while true; do
            if nc -zv -w 2 redis-queue.processing.svc.cluster.local 6379 2>/dev/null; then
              echo "Connected to Redis database successfully."
            else
              echo "ERROR: Cannot reach Redis at redis-queue:6379."
            fi
            sleep 5
          done
        volumeMounts:
        - name: data-vol
          mountPath: /data
      volumes:
      - name: data-vol
        persistentVolumeClaim:
          claimName: data-pvc
EOF

echo "Waiting for chaos to propagate..."
sleep 15

echo "Setup complete. CoreDNS is crashing, the pod is Pending, the PVC is Pending, and routing is broken. Good luck."