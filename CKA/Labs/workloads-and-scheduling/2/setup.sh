#!/bin/bash
set -e

echo "Setting up Scenario 2..."

kubectl create namespace identity --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: identity
spec:
  replicas: 2
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
    spec:
      containers:
      - name: auth
        image: nginx:alpine # Simulating app on 8080 via config or port mapping in real life
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /
            port: 80 # TRAP: App expects 8080
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          timeoutSeconds: 30 # TRAP: Too slow
          failureThreshold: 5
        volumeMounts:
        - name: certs-vol
          mountPath: /var/certs # TRAP: Wrong path
      volumes:
      - name: certs-vol
        secret:
          secretName: missing-secret # TRAP: Secret doesn't exist
EOF

echo "Scenario 2 setup complete. auth-service is failing readiness and waiting for missing secrets."