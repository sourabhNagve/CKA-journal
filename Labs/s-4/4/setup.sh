#!/bin/bash

echo "Setting up cluster environment for Lab 26 (Persistent Storage)..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (or as root) to create hostPath directories."
  exit 1
fi

# 1. Prepare hostPath directory for the PV
mkdir -p /mnt/data-pv
chmod 777 /mnt/data-pv

# 2. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: data-store
EOF

# 3. Create PersistentVolume (RWO)
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
  storageClassName: manual
  hostPath:
    path: /mnt/data-pv
EOF

# 4. Create PVC (Intentional Bug: RWX instead of RWO)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: data-store
spec:
  accessModes:
    - ReadWriteMany  # BUG: Fails to bind to RWO PV
  resources:
    requests:
      storage: 2Gi
  storageClassName: manual
EOF

# 5. Create Pod (Intentional Bug: Wrong mountPath)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: db-app
  namespace: data-store
spec:
  containers:
    - name: mysql
      image: busybox:1.32
      command: ["/bin/sh", "-c"]
      args:
        - |
          echo "Initializing DB..."
          # The app strictly expects this directory
          if touch /var/lib/mysql/init.db; then
            echo "DB Initialized successfully."
            sleep 3600
          else
            echo "ERROR: /var/lib/mysql is read-only or does not exist!"
            exit 1
          fi
      volumeMounts:
        - name: db-data
          mountPath: /var/lib/mysqll # BUG: Typo in mountPath
  volumes:
    - name: db-data
      persistentVolumeClaim:
        claimName: data-pvc
EOF

echo "Waiting for scheduler to evaluate..."
sleep 5

echo "Setup complete. The Pod and PVC are stuck."