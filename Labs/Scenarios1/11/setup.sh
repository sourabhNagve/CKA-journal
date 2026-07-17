#!/bin/bash

echo "Setting up cluster environment for Lab 11..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: cart-system
EOF

# 2. Create Secret (Key is redis-pass)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: cart-secrets
  namespace: cart-system
type: Opaque
data:
  redis-pass: c3VwZXJzZWNyZXQ=
EOF

# 3. Create Headless Service WITHOUT a selector or Endpoints
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: external-cache
  namespace: cart-system
spec:
  clusterIP: None
  ports:
  - port: 6379
    targetPort: 6379
EOF

# 4. Create Deployment (Intentional Bugs Included)
# Bug 1: Strategy is Recreate (or maxUnavailable 100%), causing downtime.
# Bug 2: InitContainer hangs because 'external-cache' has no endpoints, so no DNS record exists.
# Bug 3: App Container secretKeyRef uses wrong key 'redis_password' instead of 'redis-pass'.
# Bug 4: Readiness probe points to port 8080 instead of 80.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cart-backend
  namespace: cart-system
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 100%
      maxSurge: 25%
  selector:
    matchLabels:
      app: cart
  template:
    metadata:
      labels:
        app: cart
    spec:
      initContainers:
      - name: wait-for-cache
        image: busybox:1.32
        command: 
        - /bin/sh
        - -c
        - |
          until nslookup external-cache.cart-system.svc.cluster.local; do 
            echo "waiting for DNS..."; 
            sleep 2; 
          done;
      containers:
      - name: backend
        image: nginx:alpine
        ports:
        - containerPort: 80
        env:
        - name: CACHE_PASS
          valueFrom:
            secretKeyRef:
              name: cart-secrets
              key: redis_password
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 2
          periodSeconds: 5
EOF

echo "Allowing scheduler to process resources..."
sleep 5

echo "Setup complete. The environment is now broken and ready for the exam scenario."