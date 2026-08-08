#!/bin/bash

echo "Setting up cluster environment for Lab 8..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: telemetry
EOF

# 2. Create ConfigMap
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: log-config
  namespace: telemetry
data:
  settings.conf: |
    log_level=debug
    environment=production
EOF

# 3. Create Deployment with multiple intentional bugs
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-processor
  namespace: telemetry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: log-processor
  template:
    metadata:
      labels:
        app: log-processor
    spec:
      # BUG 1: ServiceAccount does not exist, causing ReplicaSet to fail creating pods silently
      serviceAccountName: log-sa
      initContainers:
      - name: setup-data
        image: busybox:1.32
        # BUG 2: Tries to write to /shared, but the shared-vol is not mounted in the init container
        command: ['sh', '-c', 'cp /etc/config/settings.conf /shared/settings.conf']
        volumeMounts:
        - name: config-vol
          mountPath: /etc/config
      containers:
      - name: app
        image: busybox:1.32
        command: ['sh', '-c', 'while true; do echo "\$(date) - App is running..." >> /app/logs/output.log; sleep 2; done']
        volumeMounts:
        - name: shared-vol
          mountPath: /shared
        - name: log-vol
          mountPath: /app/logs
      - name: shipper
        # BUG 3: Typo in image name
        image: buxybox:1.32 
        # BUG 4: Trying to tail from /var/log/, but the volume is mounted at /logs
        command: ['sh', '-c', 'tail -f /var/log/output.log']
        volumeMounts:
        - name: log-vol
          mountPath: /logs
      volumes:
      - name: config-vol
        configMap:
          name: log-config
      - name: shared-vol
        emptyDir: {}
      - name: log-vol
        emptyDir: {}
EOF

echo "Giving the ReplicaSet time to fail..."
sleep 5

echo "Setup complete. The environment is now broken and ready for the exam scenario."