#!/bin/bash

echo "Setting up cluster environment..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: observability
EOF

# 2. Create ConfigMap
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: scraper-config
  namespace: observability
data:
  config.yaml: |
    scrape_interval: 30s
    target_api: "https://kubernetes.default.svc"
    log_level: "info"
EOF

# 3. Create ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scraper-sa
  namespace: observability
EOF

# 4. Create Role & RoleBinding (Intentional bug: Uses Role instead of ClusterRole for cluster-scoped resources)
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scraper-role
  namespace: observability
rules:
- apiGroups: [""]
  resources: ["nodes", "namespaces"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scraper-binding
  namespace: observability
subjects:
- kind: ServiceAccount
  name: scraper-sa
  namespace: observability
roleRef:
  kind: Role
  name: scraper-role
  apiGroup: rbac.authorization.k8s.io
EOF

# 5. Create Deployment (Intentional bugs: nodeSelector won't match, and wrong mountPath for the ConfigMap)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-scraper
  namespace: observability
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scraper
  template:
    metadata:
      labels:
        app: scraper
    spec:
      serviceAccountName: scraper-sa
      nodeSelector:
        disktype: ssd
      containers:
      - name: worker
        image: curlimages/curl:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Starting scraper..."
          if [ ! -f "/etc/scraper/config.yaml" ]; then
            echo "Error: Configuration file not found at /etc/scraper/config.yaml"
            sleep 5
            exit 1
          fi

          echo "Config found. Querying API..."
          TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
          HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" -k -H "Authorization: Bearer \$TOKEN" https://kubernetes.default.svc/api/v1/nodes)

          if [ "\$HTTP_CODE" = "200" ]; then
            echo "SUCCESS: Cluster metrics gathered."
            sleep 3600
          else
            echo "Error: API returned HTTP \$HTTP_CODE (Forbidden). Needs cluster-wide access."
            sleep 5
            exit 1
          fi
        volumeMounts:
        - name: config-vol
          mountPath: /etc/config  # BUG: Should be /etc/scraper
      volumes:
      - name: config-vol
        configMap:
          name: scraper-config
EOF

echo "Waiting for the scheduler to evaluate..."
sleep 5

echo "Setup complete. The environment is now broken and ready for the exam scenario."