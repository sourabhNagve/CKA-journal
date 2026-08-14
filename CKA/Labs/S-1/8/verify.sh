#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if ServiceAccount was created
if kubectl get sa log-sa -n telemetry >/dev/null 2>&1; then
    echo "[PASS] ServiceAccount 'log-sa' created. Pods can now be scheduled."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] ServiceAccount 'log-sa' is missing. ReplicaSet cannot create pods."
fi

# Give pods a moment to spin up or crash
sleep 2

# 2. Check if the Init Container volume mount was fixed
INIT_MOUNT=$(kubectl get deploy log-processor -n telemetry -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[?(@.name=="shared-vol")].mountPath}' 2>/dev/null)
if [ "$INIT_MOUNT" == "/shared" ]; then
    echo "[PASS] 'shared-vol' successfully mounted in the 'setup-data' init container."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] 'shared-vol' is not mounted at '/shared' in the init container. (Init will fail with 'No such file or directory')."
fi

# 3. Check if the Shipper Image was corrected
SHIPPER_IMAGE=$(kubectl get deploy log-processor -n telemetry -o jsonpath='{.spec.template.spec.containers[?(@.name=="shipper")].image}' 2>/dev/null)
if [ "$SHIPPER_IMAGE" == "busybox:1.32" ] || [ "$SHIPPER_IMAGE" == "busybox" ]; then
    echo "[PASS] Shipper sidecar image typo corrected."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Shipper sidecar image is incorrect (Currently: $SHIPPER_IMAGE). Pod will be stuck in ErrImagePull."
fi

# 4. Check End-to-End Log Shipping (Verifies if the sidecar tail command/mount is fixed)
echo "Waiting 5 seconds to gather logs..."
sleep 5
LOG_OUTPUT=$(kubectl logs -n telemetry -l app=log-processor -c shipper --tail=3 2>/dev/null)

if echo "$LOG_OUTPUT" | grep -q "App is running"; then
    echo "[PASS] Shipper sidecar is successfully tailing logs from the app container."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Shipper sidecar is not outputting the correct logs. (Check the 'command' or 'volumeMounts' in the shipper container)."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi