#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# 1. Check if Node is Ready
NODE_READY=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
if [ "$NODE_READY" == "True" ]; then
    echo "[PASS] kubelet fixed! Node '$NODE_NAME' is in the Ready state."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Node '$NODE_NAME' is still NotReady. Check 'journalctl -u kubelet' for syntax errors."
fi

# 2. Check if Node is Cordoned (SchedulingDisabled)
NODE_CORDONED=$(kubectl get node "$NODE_NAME" -o jsonpath='{.spec.unschedulable}')
if [ "$NODE_CORDONED" == "true" ]; then
    echo "[PASS] Node '$NODE_NAME' is correctly cordoned (SchedulingDisabled)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Node '$NODE_NAME' is not cordoned. You must drain/cordon the node."
fi

# 3. Check if PDB trap was bypassed (Deployment scaled >= 3)
REPLICAS=$(kubectl get deploy web-store -n e-commerce -o jsonpath='{.spec.replicas}')
if [ "$REPLICAS" -ge 3 ]; then
    echo "[PASS] Deployment scaled to $REPLICAS to satisfy the PDB during eviction."
    SCORE=$((SCORE+1))
else
    # Alternative valid fix: They modified the PDB instead of scaling the deployment
    PDB_MIN=$(kubectl get pdb web-store-pdb -n e-commerce -o jsonpath='{.spec.minAvailable}' 2>/dev/null)
    if [ "$PDB_MIN" == "1" ] || [ -z "$PDB_MIN" ]; then
        echo "[PASS] PDB modified to allow eviction without scaling the deployment."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] Deployment not scaled (Replicas: $REPLICAS) and PDB not modified. Drain would hang."
    fi
fi

# Additional info
echo "--> Pods currently on $NODE_NAME in e-commerce namespace:"
kubectl get pods -n e-commerce --field-selector spec.nodeName="$NODE_NAME"

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi