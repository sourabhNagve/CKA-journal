#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if the snapshot file exists
if [ -f "/opt/backup/etcd-snapshot.db" ]; then
    echo "[PASS] etcd-snapshot.db found in /opt/backup."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] etcd-snapshot.db not found at /opt/backup/etcd-snapshot.db."
fi

# 2. Check if the snapshot was restored to the correct new directory
if [ -d "/var/lib/etcd-restored" ] && [ -d "/var/lib/etcd-restored/member" ]; then
    echo "[PASS] Snapshot data successfully restored to /var/lib/etcd-restored."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Restored data not found in /var/lib/etcd-restored. Did you run 'etcdctl snapshot restore' with --data-dir?"
fi

# 3. Check if the etcd static pod was updated to use the new directory
ETCD_MANIFEST="/etc/kubernetes/manifests/etcd.yaml"
if grep -q "path: /var/lib/etcd-restored" "$ETCD_MANIFEST"; then
    echo "[PASS] etcd.yaml correctly updated to use the new hostPath volume."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] etcd.yaml is still pointing to the old /var/lib/etcd directory or was not updated correctly."
fi

# 4. Check if the cluster is healthy and retained data
echo "Testing API server connectivity..."
if kubectl get cm critical-cluster-data -n default &>/dev/null; then
    echo "[PASS] Cluster is responsive and the critical data was retained post-restoration."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] API server is unreachable, or the critical data is missing. The etcd pod may be crash-looping."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi