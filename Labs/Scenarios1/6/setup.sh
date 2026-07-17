#!/bin/bash

echo "Setting up cluster environment..."

# 1. Create Namespaces
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: internal-api
---
apiVersion: v1
kind: Namespace
metadata:
  name: legacy-ops
EOF

# 2. Deploy API Server in internal-api
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: internal-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: internal-api
  template:
    metadata:
      labels:
        app: internal-api
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: api-svc
  namespace: internal-api
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: internal-api
EOF

# 3. Create Egress Network Policy in legacy-ops (Intentional bug: Blocks DNS and API traffic)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: legacy-egress-deny
  namespace: legacy-ops
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  # Useless egress rule just to simulate an existing broken configuration
  - to:
    - ipBlock:
        cidr: 8.8.8.8/32
    ports:
    - protocol: TCP
      port: 53
EOF

# 4. Create Naked Pod in legacy-ops (Intentional: Missing API_VERSION env var)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: report-generator
  namespace: legacy-ops
  labels:
    app: report-gen
spec:
  containers:
  - name: worker
    image: curlimages/curl:latest
    command: 
    - /bin/sh
    - -c
    - |
      echo "Fetching report data..."
      if curl -s -m 3 api-svc.internal-api.svc.cluster.local > /dev/null; then
        echo "Success: API reached."
        sleep 3600
      else
        echo "Error: Failed to reach API. Exiting."
        exit 1
      fi
EOF

# 5. Create Service in legacy-ops (Intentional bug: ClusterIP instead of NodePort 32000)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: report-svc
  namespace: legacy-ops
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: report-gen
EOF

# Wait briefly to let the pod fail
sleep 5

echo "Setup complete. The environment is now broken and ready for the exam scenario."