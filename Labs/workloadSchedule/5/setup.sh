#!/bin/bash
set -e

echo "Setting up Scenario 8..."

kubectl create namespace messaging --dry-run=client -o yaml | kubectl apply -f -

# Pre-create PVs and PVCs to bypass dynamic provisioner unpredictability in mocked clusters
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-kafka-0
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  # TRAP: Reclaim policy is Delete
  persistentVolumeReclaimPolicy: Delete
  hostPath:
    path: /tmp/kafka-0
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-kafka-1
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  hostPath:
    path: /tmp/kafka-1
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-kafka-0
  namespace: messaging
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  volumeName: pv-kafka-0
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-kafka-1
  namespace: messaging
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  volumeName: pv-kafka-1
EOF

# Create broken Service and StatefulSet
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: kafka-svc
  namespace: messaging
spec:
  # TRAP: Not headless
  ports:
  - port: 9092
    name: kafka
  selector:
    app: kafka
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
  namespace: messaging
spec:
  serviceName: "kafka-svc"
  replicas: 2
  selector:
    matchLabels:
      app: kafka
  template:
    metadata:
      labels:
        app: kafka
    spec:
      containers:
      - name: broker
        image: busybox
        command: ["/bin/sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: data
          mountPath: /var/lib/kafka/data
  # The STS will bind to the pre-created PVCs
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
EOF

echo "Scenario 8 setup complete. The PVs are vulnerable, the Service is broken, and PVCs need expansion."