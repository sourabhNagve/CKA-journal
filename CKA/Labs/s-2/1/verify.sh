#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check PVC Status & Size
PVC_STATUS=$(kubectl get pvc analytics-pvc -n analytics -o jsonpath='{.status.phase}' 2>/dev/null)
PVC_SIZE=$(kubectl get pvc analytics-pvc -n analytics -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)

if [ "$PVC_STATUS" == "Bound" ] && { [ "$PVC_SIZE" == "2Gi" ] || [ "$PVC_SIZE" == "1Gi" ]; }; then
    echo "[PASS] analytics-pvc successfully recreated and Bound."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] analytics-pvc is not Bound or is still requesting too much storage (Current: $PVC_SIZE)."
fi

# 2. Check Volume Mount Path
MOUNT_PATH=$(kubectl get deploy data-aggregator -n analytics -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}' 2>/dev/null)

if [ "$MOUNT_PATH" == "/data" ]; then
    echo "[PASS] Volume mountPath corrected to /data. (DNS can now resolve)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Volume mountPath is incorrect (Found: $MOUNT_PATH). It must be /data to prevent /etc shadowing."
fi

# 3. Check Namespace Label (NetworkPolicy resolution)
NS_LABEL=$(kubectl get ns analytics -o jsonpath='{.metadata.labels.access}' 2>/dev/null)
if [ "$NS_LABEL" == "allowed" ]; then
    echo "[PASS] Namespace 'analytics' labeled correctly to bypass NetworkPolicy."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Namespace 'analytics' is missing the 'access=allowed' label. Traffic is blocked."
fi

# 4. Check End-to-End Logs
POD_NAME=$(kubectl get pods -n analytics -l app=aggregator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    sleep 5 # Ensure at least one loop executes after potential fixes
    LOGS=$(kubectl logs "$POD_NAME" -n analytics --tail=3 2>/dev/null)
    
    if echo "$LOGS" | grep -q "SUCCESS"; then
        echo "[PASS] Pod successfully reached the API and logged SUCCESS."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] Pod is still failing to reach the API. Recent logs:"
        echo "$LOGS"
    fi
else
    echo "[FAIL] data-aggregator pod not found."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi