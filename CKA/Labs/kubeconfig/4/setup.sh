#!/bin/bash

mkdir -p /opt/course/kube4
cd /opt/course/kube4

# Create dummy CA, Client Cert, and Client Key
echo "BEGIN CERTIFICATE--omega-ca--END CERTIFICATE" > ca.crt
echo "BEGIN CERTIFICATE--cluster-admin-cert--END CERTIFICATE" > admin.crt
echo "BEGIN RSA PRIVATE KEY--cluster-admin-key--END RSA PRIVATE KEY" > admin.key

# Ensure no residual config exists from previous attempts
rm -f /opt/course/kube4/custom-config.yaml
rm -f /opt/course/kube4/extracted-token.txt

echo "✅ Environment setup complete! Begin building from scratch."