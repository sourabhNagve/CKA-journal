#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if STS has 2 replicas
STS_REPLICAS=$(kubectl get sts web-cache -n data-ops -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$STS_REPLICAS" == "2" ]; then
    echo "[PASS] StatefulSet is configured for 2 replicas."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] StatefulSet does not have 2 replicas."
fi

# 2. Check if web-cache-1 is Running
POD_STATUS=$(kubectl get pod web-cache-1 -n data-ops -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_STATUS" == "Running" ]; then
    echo "[PASS] web-cache-1 pod is Running."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] web-cache-1 pod is not Running. Current status: $POD_STATUS"
fi

# 3. Check VolumeClaimTemplate StorageClass fix
VCT_SC=$(kubectl get sts web-cache -n data-ops -o jsonpath='{.spec.volumeClaimTemplates[0].spec.storageClassName}' 2>/dev/null)
if [ "$VCT_SC" == "nvme-sc" ]; then
    echo "[PASS] VolumeClaimTemplate storageClassName is corrected."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] VolumeClaimTemplate storageClassName is incorrect. Found: $VCT_SC"
fi

# 4. Check Toleration fix
TOLERATION=$(kubectl get sts web-cache -n data-ops -o jsonpath='{.spec.template.spec.tolerations}' 2>/dev/null)
if echo "$TOLERATION" | grep -q "tier" && echo "$TOLERATION" | grep -q "cache"; then
    echo "[PASS] Pod template contains the correct toleration."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Pod template is missing the required toleration for 'tier=cache'."
fi

# Sanity Check on Constraints
POD_0_AGE=$(kubectl get pod web-cache-0 -n data-ops -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null)
echo "(Notice: Evaluator should ensure web-cache-0 was not recreated: Age timestamp is $POD_0_AGE)"

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi