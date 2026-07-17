#!/bin/bash

echo "Setting up cluster environment..."

# 1. Strip the tier=edge label from all nodes to simulate the scheduling failure
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  kubectl label node "$node" tier- 2>/dev/null || true
done

# 2. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: edge-net
EOF

# 3. Create Deployment with intentional bugs
# Bug 1: nodeSelector requires a label no node has.
# Bug 2: requiredDuringSchedulingIgnoredDuringExecution for PodAntiAffinity will fail on clusters with < 3 nodes.
# Bug 3: livenessProbe points to port 8080 instead of 80.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway-app
  namespace: edge-net
spec:
  replicas: 3
  selector:
    matchLabels:
      app: gateway
  template:
    metadata:
      labels:
        app: gateway
    spec:
      nodeSelector:
        tier: edge
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - gateway
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
EOF

# 4. Create Service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: gateway-svc
  namespace: edge-net
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: gateway
EOF

# 5. Create Ingress (Intentional bug: backend service name is wrong)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-ingress
  namespace: edge-net
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: edge.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gateway-service # Typo: Should be gateway-svc
            port:
              number: 80
EOF

echo "Giving the scheduler a moment to evaluate..."
sleep 5

echo "Setup complete. The environment is now broken and ready for the exam scenario."