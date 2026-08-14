#!/bin/bash

mkdir -p /opt/course/kube3
cd /opt/course/kube3

# Create the CA certificate for Prod
echo "BEGIN CERTIFICATE--this-is-the-prod-ca--END CERTIFICATE" > prod-ca.crt

# Generate dev.yaml
cat <<EOF > dev.yaml
apiVersion: v1
clusters:
- cluster:
    server: https://dev.example.com:6443
  name: dev-cluster
contexts:
- context:
    cluster: dev-cluster
    user: dev-user
  name: dev-ctx
current-context: dev-ctx
kind: Config
preferences: {}
users:
- name: dev-user
  user:
    token: dev-token-123
EOF

# Generate test.yaml (test-ctx intentionally uses dev-user and namespace database)
cat <<EOF > test.yaml
apiVersion: v1
clusters:
- cluster:
    server: https://test.example.com:6443
  name: test-cluster
contexts:
- context:
    cluster: test-cluster
    user: dev-user
    namespace: database
  name: test-ctx
current-context: test-ctx
kind: Config
preferences: {}
users:
- name: test-user
  user:
    token: test-token-456
EOF

# Generate prod.yaml (missing CA data)
cat <<EOF > prod.yaml
apiVersion: v1
clusters:
- cluster:
    server: https://prod.example.com:6443
  name: prod-cluster
contexts:
- context:
    cluster: prod-cluster
    user: prod-user
  name: prod-ctx
current-context: prod-ctx
kind: Config
preferences: {}
users:
- name: prod-user
  user:
    token: prod-token-789
EOF

echo "✅ Environment setup complete! Begin the scenario."