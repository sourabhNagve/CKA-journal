#!/bin/bash

echo "Setting up cluster environment for Lab 14..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: secure-enclave
EOF

# 2. Create the Secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: crypto-keys
  namespace: secure-enclave
type: Opaque
data:
  key.pem: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCg==
EOF

# 3. Create the Service (Intentional Bug: Wrong selector)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: crypto-svc
  namespace: secure-enclave
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: crypto-api # BUG: Deployment label is 'app: crypto-service'
EOF

# 4. Create the Deployment (Intentional Bugs Included)
# Bug 1: runAsNonRoot is true, but no runAsUser is provided (nginx and busybox run as root by default).
# Bug 2: Readiness probe targets port 9090 instead of 80.
# Bug 3: key-loader mounts the secret at /etc/keys, but the script expects /var/keys.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: crypto-service
  namespace: secure-enclave
spec:
  replicas: 1
  selector:
    matchLabels:
      app: crypto-service
  template:
    metadata:
      labels:
        app: crypto-service
    spec:
      securityContext:
        runAsNonRoot: true
        # BUG: Missing runAsUser: 1000
      containers:
      - name: api
        image: nginx:alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 9090 # BUG: Should be 80
          initialDelaySeconds: 2
          periodSeconds: 5
      - name: key-loader
        image: busybox:1.32
        command: 
        - /bin/sh
        - -c
        - |
          if [ -f "/var/keys/key.pem" ]; then
            echo "Key loaded successfully."
            sleep 3600
          else
            echo "Error: Key file missing at /var/keys/key.pem"
            exit 1
          fi
        volumeMounts:
        - name: secret-volume
          mountPath: /etc/keys # BUG: Should be /var/keys
      volumes:
      - name: secret-volume
        secret:
          secretName: crypto-keys
EOF

echo "Allowing the scheduler and kubelet to process resources..."
sleep 5

echo "Setup complete. The environment is now broken and ready for the exam scenario."