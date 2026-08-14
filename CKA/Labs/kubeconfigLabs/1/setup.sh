#!/bin/bash

# Create necessary directories
mkdir -p /opt/course/kubeconfigs
mkdir -p /opt/course/certs

# Create dummy certificate files for the dev user
touch /opt/course/certs/dev.crt
touch /opt/course/certs/dev.key

# Generate internal.yaml
cat <<EOF > /opt/course/kubeconfigs/internal.yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: dGhpcyBpcyB0aGUgaW50ZXJuYWwgY2EgZGF0YQ==
    server: https://10.0.0.1:6443
  name: internal-cluster
contexts:
- context:
    cluster: internal-cluster
    user: internal-admin
  name: internal-admin@internal-cluster
current-context: internal-admin@internal-cluster
kind: Config
preferences: {}
users:
- name: internal-admin
  user:
    client-certificate-data: ZHVtbXk=
    client-key-data: ZHVtbXk=
EOF

# Generate external.yaml (contains the broken cluster as well)
cat <<EOF > /opt/course/kubeconfigs/external.yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: dGhpcyBpcyB0aGUgZXh0ZXJuYWwgY2EgZGF0YQ==
    server: https://203.0.113.5:6443
  name: external-cluster
- cluster:
    certificate-authority-data: ZHVtbXk=
    server: https://192.168.1.50:8443
  name: cluster-broken
contexts:
- context:
    cluster: external-cluster
    user: external-admin
  name: external-admin@external-cluster
- context:
    cluster: cluster-broken
    user: broken-admin
  name: cluster-broken
current-context: external-admin@external-cluster
kind: Config
preferences: {}
users:
- name: external-admin
  user:
    client-certificate-data: ZHVtbXk=
    client-key-data: ZHVtbXk=
- name: broken-admin
  user:
    client-certificate-data: ZHVtbXk=
    client-key-data: ZHVtbXk=
EOF

echo "✅ Environment setup complete! You can now start the scenario."