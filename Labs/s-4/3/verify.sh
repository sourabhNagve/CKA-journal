#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if pod has 2 containers
CONTAINER_COUNT=$(kubectl get deploy legacy-app -n logging-ns -o jsonpath='{.spec.template.spec.containers[*].name}' | wc -w)
if [ "$CONTAINER_COUNT" -eq 2 ]; then
    echo "[PASS] Deployment has 2 containers configured."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Deployment does not have 2 containers (Found: $CONTAINER_COUNT)."
fi

# 2. Check if emptyDir volume exists and is mounted in both containers
VOLUME_NAME=$(kubectl get deploy legacy-app -n logging-ns -o jsonpath='{.spec.template.spec.volumes[?(@.emptyDir)].name}' | awk '{print $1}')
if [ -n "$VOLUME_NAME" ]; then
    MOUNT_1=$(kubectl get deploy legacy-app -n logging-ns -o jsonpath="{.spec.template.spec.containers[?(@.name=='app-container')].volumeMounts[?(@.name=='$VOLUME_NAME')].mountPath}")
    MOUNT_2=$(kubectl get deploy legacy-app -n logging-ns -o jsonpath="{.spec.template.spec.containers[?(@.name=='sidecar-logger')].volumeMounts[?(@.name=='$VOLUME_NAME')].mountPath}")
    
    if [ -n "$MOUNT_1" ] && [ -n "$MOUNT_2" ]; then
        echo "[PASS] Shared emptyDir volume is properly mounted in both containers."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] emptyDir volume exists, but is not mounted in both containers."
    fi
else
    echo "[FAIL] No emptyDir volume found in the pod spec."
fi

# 3. Check if Sidecar container exists and is running
SIDECAR_STATE=$(kubectl get pods -n logging-ns -l app=legacy -o jsonpath='{.items[0].status.containerStatuses[?(@.name=="sidecar-logger")].ready}' 2>/dev/null)
if [ "$SIDECAR_STATE" == "true" ]; then
    echo "[PASS] sidecar-logger container is Running and Ready."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] sidecar-logger container is either missing, crashing, or not ready."
fi

# 4. Check if Sidecar is actually streaming the logs
if [ "$SIDECAR_STATE" == "true" ]; then
    # Give it a second to generate some logs
    sleep 3 
    LOG_OUTPUT=$(kubectl logs deploy/legacy-app -n logging-ns -c sidecar-logger | tail -n 1)
    if [[ "$LOG_OUTPUT" == *"[INFO] Application processing transaction"* ]]; then
        echo "[PASS] sidecar-logger is successfully streaming logs to stdout!"
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] sidecar-logger is not streaming the correct logs. Output found: '$LOG_OUTPUT'"
    fi
else
    echo "[FAIL] Cannot check logs because sidecar is not ready."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi