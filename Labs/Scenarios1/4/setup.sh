#!/bin/bash

echo "Setting up cluster environment..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: secure-corp
EOF

# 2. Create the Secret (Note the version v2)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-creds-v2
  namespace: secure-corp
type: Opaque
data:
  password: c3VwZXJzZWNyZXQ=
EOF

# 3. Create Backend Deployment (Intentional bug: references v1 secret)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  namespace: secure-corp
spec:
  replicas: 2
  selector:
    matchLabels:
      tier: backend
  template:
    metadata:
      labels:
        tier: backend
    spec:
      containers:
      - name: api
        image: nginx:alpine
        volumeMounts:
        - name: secret-vol
          mountPath: "/etc/secrets"
          readOnly: true
      volumes:
      - name: secret-vol
        secret:
          secretName: db-creds-v1
EOF

# 4. Create Backend Service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
  namespace: secure-corp
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    tier: backend
EOF

# 5. Create Frontend Deployment
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  namespace: secure-corp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: web
        image: nginx:alpine
EOF

# 6. Create Frontend Service (NodePort)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
  namespace: secure-corp
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: frontend
EOF

# 7. Create Backend NetworkPolicy (Correctly configured to allow from frontend)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-netpol
  namespace: secure-corp
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

# 8. Create Frontend NetworkPolicy (Bugs: Denies all Ingress, wrong Egress podSelector)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-netpol
  namespace: secure-corp
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress: [] 
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend 
    ports:
    - protocol: TCP
      port: 80
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF

echo "Waiting for frontend-app to become Ready..."
kubectl wait --for=condition=Ready pod -l app=frontend -n secure-corp --timeout=60s

echo "Setup complete. The environment is now broken and ready for the exam scenario."