# setup.sh
#!/bin/bash
set -e

echo "Setting up Kustomize Lab Environment..."

# Create Namespace
kubectl create namespace ecommerce-staging --dry-run=client -o yaml | kubectl apply -f -

# Setup directories
WORK_DIR="/root/cka-lab/kustomize-app"
mkdir -p ${WORK_DIR}/base
mkdir -p ${WORK_DIR}/staging

# Create base manifests
cat << 'EOF' > ${WORK_DIR}/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
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
      - name: nginx
        image: nginx:1.24.0
        ports:
        - containerPort: 80
EOF

cat << 'EOF' > ${WORK_DIR}/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOF

cat << 'EOF' > ${WORK_DIR}/base/kustomization.yaml
resources:
- deployment.yaml
- service.yaml
EOF

# Create broken staging manifests
cat << 'EOF' > ${WORK_DIR}/staging/kustomization.yaml
# Intentional Mistake 1: Wrong path to base
resources:
- ../bases

# Intentional Mistake 2: Missing namespace declaration
# Intentional Mistake 3: Missing namePrefix declaration

patches:
- path: patch.yaml
EOF

cat << 'EOF' > ${WORK_DIR}/staging/patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  template:
    spec:
      containers:
      # Intentional Mistake 4: Incorrect container name (base uses 'nginx')
      - name: nginx-container
        image: nginx:1.25.3-alpine
        env:
        - name: APP_ENV
          value: staging
EOF

# Set permissions
chmod -R 755 ${WORK_DIR}

echo "Setup complete. Proceed with the exam scenario."