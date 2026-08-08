#!/bin/bash

echo "Setting up node-level environment for Lab 15..."

# Ensure the script is run with sudo privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (or as root) since it modifies /etc/kubernetes/manifests"
  exit 1
fi

MANIFEST_DIR="/etc/kubernetes/manifests"

# Ensure we are on a kubeadm control-plane node
if [ ! -d "$MANIFEST_DIR" ]; then
    echo "Error: $MANIFEST_DIR does not exist."
    echo "This lab must be run on the control-plane node of a kubeadm-provisioned cluster."
    exit 1
fi

if [ ! -f "$MANIFEST_DIR/kube-scheduler.yaml" ]; then
    echo "Error: kube-scheduler.yaml not found in $MANIFEST_DIR. Cannot proceed."
    exit 1
fi

echo "Deploying 'web-front' to demonstrate scheduling failure..."
# Run as the regular user who invoked sudo (if applicable) to place the deployment in their context, 
# or just use standard KUBECONFIG if root has it.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-front
  namespace: default
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
EOF

echo "Introducing failure into kube-scheduler..."
# Backup the original scheduler just in case of catastrophic failure during setup
cp "$MANIFEST_DIR/kube-scheduler.yaml" "/tmp/kube-scheduler.yaml.bak"

# Intentional Bug 1: Typo in the command arguments (--leader-elect=true -> --leader-elect=truee)
sed -i 's/--leader-elect=true/--leader-elect=truee/g' "$MANIFEST_DIR/kube-scheduler.yaml"

echo "Deploying broken static pod 'audit-logger'..."
# Intentional Bug 2: Typo in image name (busyboxx) which will cause ErrImagePull/ImagePullBackOff for the static pod
cat <<EOF > "$MANIFEST_DIR/audit-logger.yaml"
apiVersion: v1
kind: Pod
metadata:
  name: audit-logger
  namespace: kube-system
spec:
  containers:
  - name: logger
    image: busyboxx:1.32
    command: ["/bin/sh", "-c", "while true; do echo 'Audit log active'; sleep 60; done"]
EOF

echo "Restarting kubelet to hasten the application of broken manifests..."
systemctl restart kubelet

echo "Waiting for the cluster to degrade (this takes ~10 seconds)..."
sleep 10

echo "Setup complete. The kube-scheduler is now broken and workloads cannot be scheduled."