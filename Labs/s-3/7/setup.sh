# #!/bin/bash

# echo "Setting up node-level environment for Lab 21..."

# if [ "$EUID" -ne 0 ]; then
#   echo "Please run this script with sudo (or as root)."
#   exit 1
# fi

# SYSTEMD_FILE="/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
# if [ ! -f "$SYSTEMD_FILE" ]; then
#     echo "Error: $SYSTEMD_FILE does not exist. Must be a kubeadm node."
#     exit 1
# fi

# kubectl apply -f - <<EOF
# apiVersion: v1
# kind: Namespace
# metadata:
#   name: e-commerce
# ---
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   name: web-store
#   namespace: e-commerce
# spec:
#   replicas: 2
#   selector:
#     matchLabels:
#       app: web
#   template:
#     metadata:
#       labels:
#         app: web
#     spec:
#       containers:
#       - name: nginx
#         image: nginx:alpine
#         ports:
#         - containerPort: 80
# ---
# apiVersion: policy/v1
# kind: PodDisruptionBudget
# metadata:
#   name: web-store-pdb
#   namespace: e-commerce
# spec:
#   minAvailable: 2
#   selector:
#     matchLabels:
#       app: web
# EOF

# echo "Waiting for workloads to deploy before breaking the node..."
# sleep 10

# echo "Injecting fatal error into kubelet systemd configuration..."
# cp "$SYSTEMD_FILE" "/tmp/10-kubeadm.conf.bak"

# # This typo breaks the path to the kubeconfig, guaranteeing a crash
# sed -i 's/kubelet.conf/kubelet.conff/g' "$SYSTEMD_FILE"

# systemctl daemon-reload
# systemctl restart kubelet

# echo "Waiting for the node to transition to NotReady (takes about 30 seconds)..."
# for i in {1..10}; do echo -n "."; sleep 3; done
# echo ""

# echo "Setup complete. The kubelet is crashing, the node is NotReady, and the PDB blocks draining."

#!/bin/bash

echo "Setting up node-level environment for Lab 21..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (or as root)."
  exit 1
fi

KUBELET_CONFIG="/var/lib/kubelet/config.yaml"
if [ ! -f "$KUBELET_CONFIG" ]; then
    echo "Error: $KUBELET_CONFIG does not exist. Ensure you are on a Kubernetes node."
    exit 1
fi

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: e-commerce
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-store
  namespace: e-commerce
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-store-pdb
  namespace: e-commerce
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web
EOF

echo "Waiting for workloads to deploy before breaking the node..."
sleep 10

echo "Injecting fatal YAML syntax error into kubelet configuration..."
cp "$KUBELET_CONFIG" "/tmp/config.yaml.bak"

# Appending an unclosed bracket to intentionally break the YAML parser
echo "broken_syntax: [" >> "$KUBELET_CONFIG"

systemctl restart kubelet

echo "Waiting for the node to transition to NotReady (takes about 30 seconds)..."
for i in {1..10}; do echo -n "."; sleep 3; done
echo ""

echo "Setup complete. The kubelet is crashing due to a YAML parsing error, the node is NotReady, and the PDB blocks draining."