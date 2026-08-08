#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# 1. Check if Node is Cordoned
NODE_CORDONED=$(kubectl get node "$NODE_NAME" -o jsonpath='{.spec.unschedulable}')
if [ "$NODE_CORDONED" == "true" ]; then
    echo "[PASS] Node '$NODE_NAME' is successfully cordoned (SchedulingDisabled)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Node '$NODE_NAME' is not cordoned. The drain did not complete."
fi

# 2. Check PDB Bypass (Scaling)
HA_REPLICAS=$(kubectl get deploy ha-app -n upgrade-prep -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$HA_REPLICAS" -ge 3 ]; then
    echo "[PASS] 'ha-app' successfully scaled to >=3 to satisfy the PDB during eviction."
    SCORE=$((SCORE+1))
else
    PDB_MIN=$(kubectl get pdb ha-app-pdb -n upgrade-prep -o jsonpath='{.spec.minAvailable}' 2>/dev/null)
    if [ "$PDB_MIN" == "1" ] || [ -z "$PDB_MIN" ]; then
        echo "[PASS] PDB modified to allow eviction without scaling the deployment."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] 'ha-app' was not scaled (Replicas: $HA_REPLICAS). The drain command would hang indefinitely."
    fi
fi

# 3. Check Eviction Success (Are non-DaemonSet pods gone from this node?)
# We specifically look for the unmanaged pod and the emptyDir pod.
LEGACY_POD=$(kubectl get pods -n upgrade-prep -l app!=monitor --field-selector spec.nodeName="$NODE_NAME" -o name 2>/dev/null)
if [ -z "$LEGACY_POD" ]; then
    echo "[PASS] All non-DaemonSet workloads successfully evacuated from the node."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Workloads are still running on the node:"
    echo "$LEGACY_POD"
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi