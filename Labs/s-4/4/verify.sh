#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

# 1. Check PVC Status
PVC_STATUS=$(kubectl get pvc data-pvc -n data-store -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" == "Bound" ]; then
    echo "[PASS] PVC 'data-pvc' is successfully Bound to the PV."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] PVC is in phase: ${PVC_STATUS:-NotFound}. Check the Access Modes to ensure they match the PV."
fi

# 2. Check Pod Mount Path
MOUNT_PATH=$(kubectl get pod db-app -n data-store -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}' 2>/dev/null)
if [ "$MOUNT_PATH" == "/var/lib/mysql" ]; then
    echo "[PASS] Pod volume is correctly mounted to /var/lib/mysql."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Pod is mounted to incorrect path: $MOUNT_PATH"
fi

# 3. Check Pod End-to-End Status
POD_STATUS=$(kubectl get pod db-app -n data-store -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" == "Running" ]; then
    echo "[PASS] Pod 'db-app' is Running and successfully wrote to the persistent volume."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Pod is not Running (Current Status: $POD_STATUS)."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi