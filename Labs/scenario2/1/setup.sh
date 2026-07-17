#!/bin/bash

echo "Setting up cluster environment for Lab 12..."

# 1. Create Namespaces
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: internal-services
---
apiVersion: v1
kind: Namespace
metadata:
  name: analytics
EOF

# 2. Deploy Target API in internal-services
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-api
  namespace: internal-services
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: web
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: data-api
  namespace: internal-services
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: api
EOF

# 3. Create NetworkPolicy blocking traffic unless namespace is labeled
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-api-access
  namespace: internal-services
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          access: allowed
    ports:
    - protocol: TCP
      port: 80
EOF

# 4. Create PV (Capacity: 2Gi)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: analytics-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: "/mnt/analytics-data"
EOF

# 5. Create PVC (Intentional Bug: Requests 5Gi, preventing binding to the 2Gi PV)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: analytics-pvc
  namespace: analytics
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 5Gi
EOF

# 6. Create Aggregator Deployment
# Intentional Bug 2: Mounts the volume to /etc, overwriting /etc/resolv.conf and breaking DNS.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-aggregator
  namespace: analytics
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aggregator
  template:
    metadata:
      labels:
        app: aggregator
    spec:
      containers:
      - name: worker
        image: busybox:1.32
        command: 
        - /bin/sh
        - -c
        - |
          while true; do 
            if wget -qO- --timeout=2 http://data-api.internal-services.svc.cluster.local > /dev/null 2>&1; then 
              echo "SUCCESS"
            else 
              echo "FAIL"
            fi
            sleep 3
          done
        volumeMounts:
        - name: data-vol
          mountPath: /etc
      volumes:
      - name: data-vol
        persistentVolumeClaim:
          claimName: analytics-pvc
EOF

echo "Waiting for background resources to initialize..."
sleep 10

echo "Setup complete. The environment is now broken and ready for the exam scenario."