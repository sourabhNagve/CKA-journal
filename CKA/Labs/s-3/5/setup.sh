#!/bin/bash

echo "Setting up cluster environment for Lab 19 (Networking, Advanced Scheduling, and TLS)..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (or as root) to create files in /opt/"
  exit 1
fi

# 1. Break Kube-Proxy
echo "Injecting error into kube-proxy ConfigMap..."
if kubectl get cm kube-proxy -n kube-system >/dev/null 2>&1; then
    # Backup the original config
    kubectl get cm kube-proxy -n kube-system -o yaml > /tmp/kube-proxy-backup.yaml
    
    # Introduce a typo: change 'metricsBindAddress' to 'metricsBindAddresss'
    kubectl get cm kube-proxy -n kube-system -o yaml | sed 's/metricsBindAddress/metricsBindAddresss/g' | kubectl apply -f - >/dev/null
    
    # Restart kube-proxy to apply the broken config
    kubectl delete pods -n kube-system -l k8s-app=kube-proxy >/dev/null
else
    echo "Warning: kube-proxy ConfigMap not found (Are you using Cilium/eBPF?). Skipping kube-proxy breakage, proceeding with other tasks."
fi

# 2. Create Namespaces
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: payments
EOF

# 3. Generate TLS Certificates
echo "Generating dummy TLS certificates..."
mkdir -p /opt/payment-certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /opt/payment-certs/tls.key \
    -out /opt/payment-certs/tls.crt \
    -subj "/CN=payment.example.com" 2>/dev/null

# 4. Create Broken TLS Secret (Type: Opaque instead of kubernetes.io/tls)
echo "Creating misconfigured TLS Secret..."
kubectl create secret generic payment-tls \
    --from-file=tls.crt=/opt/payment-certs/tls.crt \
    --from-file=tls.key=/opt/payment-certs/tls.key \
    -n payments

# 5. Create Deployment with strict TopologySpreadConstraints
echo "Creating deployment with unsatisfiable scheduling constraints..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-processor
  namespace: payments
spec:
  replicas: 5
  selector:
    matchLabels:
      app: payment
  template:
    metadata:
      labels:
        app: payment
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule # BUG: Will prevent scheduling of all 5 replicas on small clusters
        labelSelector:
          matchLabels:
            app: payment
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
EOF

# 6. Create Service and Ingress
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: payment-svc
  namespace: payments
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: payment
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: payment-ingress
  namespace: payments
spec:
  tls:
  - hosts:
    - payment.example.com
    secretName: payment-tls
  rules:
  - host: payment.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: payment-svc
            port:
              number: 80
EOF

echo "Waiting for scheduler and daemonsets to evaluate..."
sleep 10

echo "Setup complete. The environment is now broken and ready for the exam scenario."