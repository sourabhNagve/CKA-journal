c#!/bin/bash

echo "Setting up cluster environment..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: data-processing
EOF

# 2. Create ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: analyzer-sa
  namespace: data-processing
EOF

# 3. Create Role
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: data-processing
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
EOF

# 4. Create RoleBinding (Intentional bug: bound to 'default' SA instead of 'analyzer-sa')
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: analyzer-binding
  namespace: data-processing
subjects:
- kind: ServiceAccount
  name: default
  namespace: data-processing
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

# 5. Create Deployment (Intentional bugs: Missing fsGroup, memory limit too low)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: data-analyzer
  namespace: data-processing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: analyzer
  template:
    metadata:
      labels:
        app: analyzer
    spec:
      serviceAccountName: analyzer-sa
      securityContext:
        runAsUser: 1000
        # Intentional bug: Missing fsGroup: 1000 to allow writing to the root-owned volume
      containers:
      - name: analyzer
        image: curlimages/curl:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Testing write access..."
          touch /data/test || { echo "Permission denied writing to /data"; sleep 5; exit 1; }

          echo "Consuming memory..."
          # This writes 60MB to the tmpfs volume, which counts against the pod's memory limit.
          dd if=/dev/zero of=/data/memtest bs=1M count=60 2>/dev/null
          echo "Memory allocation survived."

          echo "Querying API..."
          TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
          HTTP_CODE=\$(curl -k -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer \$TOKEN" https://kubernetes.default.svc/api/v1/namespaces/data-processing/pods)

          if [ "\$HTTP_CODE" == "200" ]; then
            echo "SUCCESS: All tests passed."
            sleep 3600
          else
            echo "FAIL: API query returned \$HTTP_CODE"
            sleep 5
            exit 1
          fi
        resources:
          limits:
            memory: 40Mi # Intentional bug: Too low for the 60MB allocation test
        volumeMounts:
        - name: data-vol
          mountPath: /data
      volumes:
      - name: data-vol
        emptyDir:
          medium: Memory
EOF

echo "Waiting for pod to fail..."
sleep 10

echo "Setup complete. The environment is now broken and ready for the exam scenario."