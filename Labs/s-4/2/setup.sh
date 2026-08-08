#!/bin/bash

echo "Setting up cluster environment for Lab 24 (User Authentication & CSR)..."

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo (or as root). It creates files in /opt/."
  exit 1
fi

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: dev-team
EOF

# 2. Generate Private Key and CSR for Jane
echo "Generating private key and CSR for user 'jane'..."
mkdir -p /opt/jane

openssl req -new -newkey rsa:2048 -nodes \
  -keyout /opt/jane/jane.key \
  -out /opt/jane/jane.csr \
  -subj "/CN=jane/O=developers" 2>/dev/null

# Clean up any old kubeconfig if the lab is being re-run
rm -f /opt/jane/jane.kubeconfig

echo "Setup complete. Jane's files are waiting in /opt/jane/."