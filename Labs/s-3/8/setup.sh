

#!/bin/bash

echo "Setting up node-level environment for Lab 22..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (or as root)."
  exit 1
fi

API_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: observability
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-logger
  namespace: observability
spec:
  selector:
    matchLabels:
      name: fluentd-logger
  template:
    metadata:
      labels:
        name: fluentd-logger
    spec:
      containers:
      - name: fluentd
        image: busybox:1.32
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Log collection started successfully."
          sleep 3600
        volumeMounts:
        - name: varlog
          mountPath: /var/log/containers
      volumes:
      - name: varlog
        hostPath:
          path: /var/logs/containers # BUG: Typo (logs instead of log)
          type: Directory            # THE FIX: Forces mount to fail if directory doesn't exist
EOF

echo "Allowing workload to initialize before breaking the control plane..."
sleep 5

echo "Injecting syntax error into kube-apiserver manifest..."
cp "$API_MANIFEST" "/tmp/kube-apiserver.yaml.bak"

sed -i 's/--authorization-mode=Node,RBAC/--authorization-mode=Node,RBACC/g' "$API_MANIFEST"

echo "Waiting for the API server to crash..."
sleep 15

echo "Setup complete. The kube-apiserver is down. kubectl commands will now fail."