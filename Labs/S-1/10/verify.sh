#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check Node Labels (Did they satisfy the nodeSelector?)
NODE_LABELS=$(kubectl get nodes -l disktype=ssd -o name 2>/dev/null)
if [ -n "$NODE_LABELS" ]; then
    echo "[PASS] At least one node is labeled with 'disktype=ssd'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] No nodes are labeled with 'disktype=ssd'. Pod will remain Pending."
fi

# 2. Check Volume Mount Path (Did they fix the config map mount?)
MOUNT_PATH=$(kubectl get deploy cluster-scraper -n observability -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="config-vol")].mountPath}' 2>/dev/null)
if [ "$MOUNT_PATH" == "/etc/scraper" ]; then
    echo "[PASS] ConfigMap correctly mounted at '/etc/scraper'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] ConfigMap mountPath is incorrect. Found: $MOUNT_PATH."
fi

# 3. Check RBAC configuration (Did they use a ClusterRole for cluster-wide resources?)
CAN_LIST_NODES=$(kubectl auth can-i list nodes --as=system:serviceaccount:observability:scraper-sa 2>/dev/null)
CAN_LIST_NS=$(kubectl auth can-i list namespaces --as=system:serviceaccount:observability:scraper-sa 2>/dev/null)

if [ "$CAN_LIST_NODES" == "yes" ] && [ "$CAN_LIST_NS" == "yes" ]; then
    echo "[PASS] ServiceAccount 'scraper-sa' has proper cluster-wide permissions."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] ServiceAccount 'scraper-sa' cannot list cluster resources. (Did you use a ClusterRole and ClusterRoleBinding?)"
fi

# 4. Check End-to-End Execution via Logs
POD_NAME=$(kubectl get pods -n observability -l app=scraper -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    # Give the pod a moment to complete its curl request
    sleep 3
    LOGS=$(kubectl logs "$POD_NAME" -n observability 2>/dev/null | tail -n 2)
    
    if echo "$LOGS" | grep -q "SUCCESS"; then
        echo "[PASS] Pod is running and successfully queried the cluster API."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] Pod script failed. Recent logs: $LOGS"
    fi
else
    echo "[FAIL] cluster-scraper pod not found."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi