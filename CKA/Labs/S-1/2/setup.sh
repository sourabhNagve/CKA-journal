#!/bin/bash

echo "Setting up cluster environment..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: data-ops
EOF

# 2. Create StorageClass
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nvme-sc
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: Immediate
EOF

# 3. Create Persistent Volumes
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-cache-0
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nvme-sc
  hostPath:
    path: "/mnt/data/cache-0"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-cache-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nvme-sc
  hostPath:
    path: "/mnt/data/cache-1"
EOF

# 4. Create PVC for replica 0 manually (Correct StorageClass so replica 0 starts)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-web-cache-0
  namespace: data-ops
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: nvme-sc
EOF

# 5. Create StatefulSet with missing toleration and INCORRECT StorageClass in VolumeClaimTemplate
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-cache
  namespace: data-ops
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-cache
  serviceName: "web-cache-svc"
  template:
    metadata:
      labels:
        app: web-cache
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
      storageClassName: nvme-stor
EOF

# 6. Wait for replica 0 to run
echo "Waiting for web-cache-0 to become Ready..."
kubectl wait --for=condition=Ready pod/web-cache-0 -n data-ops --timeout=90s

# 7. Apply Taint to all scheduleable nodes
echo "Tainting worker nodes to block new pods..."
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  # Skip control plane nodes to avoid breaking cluster internals
  if ! kubectl get node "$node" -o jsonpath='{.spec.taints[*].key}' | grep -q "control-plane"; then
    kubectl taint node "$node" tier=cache:NoSchedule --overwrite
  fi
done

# 8. Scale StatefulSet to 2 (This triggers the creation of the broken replica 1)
echo "Scaling StatefulSet to 2 to trigger the scenario..."
kubectl scale sts web-cache --replicas=2 -n data-ops

# Give it a few seconds to generate the pending pod and PVC
sleep 5

echo "Setup complete. The environment is now broken and ready for the exam scenario."