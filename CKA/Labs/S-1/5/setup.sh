#!/bin/bash

echo "Setting up cluster environment..."

# 1. Ensure Control Plane has the standard taint (for test environments like kind/minikube that might remove it)
CONTROL_PLANE_NODE=$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$CONTROL_PLANE_NODE" ]; then
  kubectl taint node "$CONTROL_PLANE_NODE" node-role.kubernetes.io/control-plane:NoSchedule --overwrite >/dev/null 2>&1 || true
fi

# 2. Create Namespaces
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce
---
apiVersion: v1
kind: Namespace
metadata:
  name: security-ops
EOF

# 3. Create Deployment (Intentional bug: Readiness probe points to 404 path)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-app
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ecommerce-app
  template:
    metadata:
      labels:
        app: ecommerce-app
    spec:
      containers:
      - name: web
        image: nginx:alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 5
EOF

# 4. Create Service (Targeting port 80)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ecommerce-svc
  namespace: ecommerce
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: ecommerce-app
EOF

# 5. Create Ingress (Intentional bug: Backend port points to 8080 instead of 80)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ecommerce-ingress
  namespace: ecommerce
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ecommerce-svc
            port:
              number: 8080
EOF

# 6. Create DaemonSet (Intentional bug: Missing tolerations for control-plane)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-defender
  namespace: security-ops
spec:
  selector:
    matchLabels:
      app: defender
  template:
    metadata:
      labels:
        app: defender
    spec:
      containers:
      - name: agent
        image: busybox:1.32
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Waiting for resources to initialize..."
sleep 10

echo "Setup complete. The environment is now broken and ready for the exam scenario."