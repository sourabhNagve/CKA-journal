#!/bin/bash
# ======================================================================
# Severity-1 Outage Scenario Setup Script (CKA/Killer.sh Level)
# Run as root on the controlplane node
# ======================================================================

set -e

echo -e "\e[34m[1/5] Setting up target cluster state...\e[0m"
# 1. Create the namespace and deploy the pods with specific images
kubectl create namespace financial-core --dry-run=client -o yaml | kubectl apply -f -
kubectl run nginx --image=nginx:1.23.0 -n financial-core
kubectl run redis --image=redis:7.0-alpine -n financial-core

# Wait for pods to be fully running so they are captured in the snapshot
echo "Waiting for financial-core pods to be Ready..."
kubectl wait --for=condition=ready pod/nginx -n financial-core --timeout=60s
kubectl wait --for=condition=ready pod/redis -n financial-core --timeout=60s

echo -e "\e[34m[2/5] Taking the ETCD Snapshot...\e[0m"
# 2. Take the ETCD backup to the required location
mkdir -p /opt/backups
ETCDCTL_API=3 etcdctl snapshot save /opt/backups/etcd-snapshot.db \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  --endpoints=127.0.0.1:2379

echo -e "\e[32mSnapshot saved to /opt/backups/etcd-snapshot.db\e[0m"

echo -e "\e[34m[3/5] Simulating Junior Admin Error (Deleting Namespace)...\e[0m"
# 3. Delete the namespace synchronously BEFORE breaking the API server
# (If we break the API server while this is deleting, it gets stuck in Terminating)
kubectl delete namespace financial-core

echo -e "\e[34m[4/5] Breaking node01 (kubelet failure)...\e[0m"
# 4. SSH into node01 and introduce a configuration error in the kubelet config
# This inserts an invalid YAML key at the top of the config file, causing kubelet to crash on startup.
ssh -o StrictHostKeyChecking=no node01 "sed -i '1s/^/invalidConfigKey: \"Trigger Crash\"\n/' /var/lib/kubelet/config.yaml"
ssh -o StrictHostKeyChecking=no node01 "systemctl restart kubelet" || true

echo -e "\e[34m[5/5] Breaking controlplane (kube-apiserver crash)...\e[0m"
# 5. Modify the static pod manifest for the API server to point to a non-existent certificate
# This will cause the kube-apiserver container to enter a CrashLoopBackOff.
sed -i 's/apiserver-kubelet-client.crt/apiserver-kubelet-client-wrong.crt/g' /etc/kubernetes/manifests/kube-apiserver.yaml

echo -e "\e[33mWaiting 15 seconds for failures to propagate...\e[0m"
sleep 15

echo -e "\e[31m=================================================================\e[0m"
echo -e "\e[31m SCENARIO SETUP COMPLETE. THE CLUSTER IS NOW BROKEN.\e[0m"
echo -e "\e[31m=================================================================\e[0m"
echo "Verify current state:"
echo "1. 'kubectl get nodes' should hang or fail (API Server down)."
echo "2. 'crictl ps' will show kube-apiserver exiting."
echo "Good luck with your exam scenario!"