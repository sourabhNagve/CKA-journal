#!/bin/bash

echo "Setting up cluster environment for Lab 18 (Cluster DNS & Routing)..."

# 1. Backup existing CoreDNS config
echo "Backing up CoreDNS ConfigMap..."
kubectl get cm coredns -n kube-system -o yaml > /tmp/coredns-backup.yaml

# 2. Break CoreDNS by replacing the valid 'health' plugin with 'brokenhealth'
echo "Injecting syntax error into CoreDNS ConfigMap..."
kubectl get cm coredns -n kube-system -o yaml | sed 's/health/brokenhealth/g' | kubectl apply -f - >/dev/null

# Force CoreDNS to restart and crash
kubectl delete pods -n kube-system -l k8s-app=kube-dns >/dev/null

# 3. Create Namespaces
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: auth-ns
---
apiVersion: v1
kind: Namespace
metadata:
  name: db-ns
EOF

# 4. Create Database Deployment and Service (Intentional Bug: Service selector typo)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-backend
  namespace: db-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: db-service
  namespace: db-ns
spec:
  ports:
  - port: 6379
    targetPort: 6379
  selector:
    app: database # BUG: should be app: db
EOF

# 5. Create Auth Deployment
# Intentional Bug: dnsPolicy is set to 'Default'. This causes the pod to inherit the node's /etc/resolv.conf.
# It will NOT be able to resolve cluster domains (.svc.cluster.local) even after CoreDNS is fixed!
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: auth-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auth
  template:
    metadata:
      labels:
        app: auth
    spec:
      dnsPolicy: Default # BUG: Should be ClusterFirst or removed
      initContainers:
      - name: wait-for-db
        image: busybox:1.32
        command: 
        - /bin/sh
        - -c
        - |
          echo "Waiting for db-service to resolve and accept connections..."
          until nc -z -w 2 db-service.db-ns.svc.cluster.local 6379; do 
            echo "Waiting..."; 
            sleep 2; 
          done;
          echo "DB reached!"
      containers:
      - name: auth-app
        image: nginx:alpine
        command: ["/bin/sh", "-c", "echo 'Auth Service Ready' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
        ports:
        - containerPort: 80
EOF

echo "Waiting for CoreDNS to crash and pods to fail..."
sleep 10

echo "Setup complete. CoreDNS is broken, and workloads are failing."