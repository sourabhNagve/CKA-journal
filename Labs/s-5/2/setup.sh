#!/bin/bash

echo "Setting up Killer.sh Speed Drill Round 2..."

# ==========================================
# Question 1 Setup: Scheduling Gauntlet
# ==========================================
kubectl create ns processing --dry-run=client -o yaml | kubectl apply -f - >/dev/null
WORKER_NODE=$(kubectl get nodes | grep -v "control-plane" | awk 'NR>1 {print $1}' | head -n 1)
if [ -z "$WORKER_NODE" ]; then
    WORKER_NODE=$(kubectl get nodes | awk 'NR>1 {print $1}' | head -n 1) # Fallback to master if single node
fi
echo "Labeling and tainting node: $WORKER_NODE"
kubectl label node "$WORKER_NODE" hardware=gpu --overwrite >/dev/null
kubectl taint node "$WORKER_NODE" maintenance=active:NoSchedule --overwrite >/dev/null

# ==========================================
# Question 2 Setup: Legacy Logger
# ==========================================
kubectl apply -f - <<EOF >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: legacy-app
  namespace: default
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c", "while true; do echo 'App is running' >> /var/log/legacy/output.log; sleep 5; done"]
    volumeMounts:
    - name: log-volume
      mountPath: /var/log/legacy
  volumes:
  - name: log-volume
    emptyDir: {}
EOF

# ==========================================
# Question 3 Setup: Ingress Splitter
# ==========================================
kubectl create ns media-ns --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create svc clusterip video-svc --tcp=8080:80 -n media-ns --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl create svc clusterip audio-svc --tcp=9090:80 -n media-ns --dry-run=client -o yaml | kubectl apply -f - >/dev/null

echo "Setup complete. Start your 18-minute timer!"