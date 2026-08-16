#!/bin/bash
set -e

echo "Setting up Scenario 6..."

kubectl create namespace transactions --dry-run=client -o yaml | kubectl apply -f -

# Create the broken Deployment
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-processor
  namespace: transactions
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-processor
  template:
    metadata:
      labels:
        app: order-processor
    spec:
      initContainers:
      - name: db-migrate
        image: busybox
        # TRAP: ConfigMap doesn't exist, command fails
        command: ["sh", "/scripts/migrate.sh"]
        volumeMounts:
        - name: script-vol
          mountPath: /scripts
      containers:
      - name: app
        image: nginx:alpine
        resources:
          requests:
            cpu: 100m
      volumes:
      - name: script-vol
        configMap:
          name: db-init-script
          defaultMode: 0777
EOF

# Create the HPA without behavior block
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: order-hpa
  namespace: transactions
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-processor
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF

echo "Scenario 6 setup complete. InitContainer is crashing due to missing ConfigMap, and HPA scales down too aggressively."