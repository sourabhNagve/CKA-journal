#!/bin/bash

mkdir -p /opt/course/kube

# Generate bloated config.yaml
cat <<EOF > /opt/course/kube/config.yaml
apiVersion: v1
clusters:
- cluster:
    server: https://10.0.0.1:6443
  name: legacy-cluster
- cluster:
    server: https://10.0.0.2:6443
  name: prod-cluster
- cluster:
    server: https://10.0.0.3:6443
  name: staging-cluster
- cluster:
    server: https://10.0.0.4:6443
  name: dev-cluster
contexts:
- context:
    cluster: legacy-cluster
    user: legacy-admin
  name: legacy-ctx
- context:
    cluster: prod-cluster
    user: prod-admin
  name: prod-ctx
- context:
    cluster: staging-cluster
    user: staging-user
  name: staging-ctx
- context:
    cluster: dev-cluster
    user: dev-user
  name: dev-ctx
current-context: staging-ctx
kind: Config
preferences: {}
users:
- name: legacy-admin
  user:
    token: old-token-123
- name: prod-admin
  user:
    client-certificate-data: VGhpcyBpcyB0aGUgcHJvZCBjZXJ0aWZpY2F0ZQ==
    client-key-data: VGhpcyBpcyB0aGUgcHJvZCBrZXk=
- name: staging-user
  user:
    token: staging-token-456
- name: dev-user
  user:
    token: dev-token-789
EOF

echo "✅ Environment setup complete! Begin the scenario."