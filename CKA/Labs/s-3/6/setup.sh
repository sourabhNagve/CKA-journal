#!/bin/bash

echo "Setting up cluster environment for Lab 20 (HPA, StartupProbes, and RBAC)..."

# 1. Create Namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: edge-routing
EOF

# 2. Create ServiceAccount
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gateway-sa
  namespace: edge-routing
EOF

# 3. Create Role and RoleBinding (Intentional Bug 1: Wrong verbs)
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: gateway-role
  namespace: edge-routing
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create", "delete"] # BUG: Pod needs 'get' and 'list'
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: gateway-binding
  namespace: edge-routing
subjects:
- kind: ServiceAccount
  name: gateway-sa
  namespace: edge-routing
roleRef:
  kind: Role
  name: gateway-role
  apiGroup: rbac.authorization.k8s.io
EOF

# 4. Create Deployment 
# Intentional Bug 2: No resource requests (Breaks HPA).
# Intentional Bug 3: startupProbe fails too fast. initialDelay 2 + (period 2 * threshold 2) = 6 seconds. The app sleeps for 10.
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: edge-routing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gateway
  template:
    metadata:
      labels:
        app: gateway
    spec:
      serviceAccountName: gateway-sa
      containers:
      - name: gateway
        image: curlimages/curl:latest
        command: 
        - /bin/sh
        - -c
        - |
          echo "Booting legacy application... (takes 10 seconds)"
          sleep 10
          echo "Application started."
          
          while true; do
            TOKEN=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
            HTTP_CODE=\$(curl -s -o /dev/null -w "%{http_code}" -k -H "Authorization: Bearer \$TOKEN" https://kubernetes.default.svc/api/v1/namespaces/edge-routing/configmaps)
            
            if [ "\$HTTP_CODE" = "200" ]; then
              echo "SUCCESS: ConfigMaps retrieved"
              touch /tmp/healthy
            else
              echo "FAIL: API returned HTTP \$HTTP_CODE (Forbidden). Needs get/list access."
              rm -f /tmp/healthy
            fi
            sleep 5
          done
        startupProbe:
          exec:
            command:
            - cat
            - /tmp/healthy
          initialDelaySeconds: 2
          periodSeconds: 2
          failureThreshold: 2 # BUG: Fails too quickly
EOF

# 5. Create HPA
kubectl apply -f - <<EOF
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: gateway-hpa
  namespace: edge-routing
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-gateway
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 50
EOF

echo "Allowing the pod to crash and HPA to initialize..."
sleep 15

echo "Setup complete. The environment is now broken and ready for the exam scenario."