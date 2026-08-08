#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if fsGroup is configured
FS_GROUP=$(kubectl get deploy data-analyzer -n data-processing -o jsonpath='{.spec.template.spec.securityContext.fsGroup}' 2>/dev/null)
if [ -n "$FS_GROUP" ]; then
    echo "[PASS] fsGroup is configured in the Pod SecurityContext."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] fsGroup is missing in SecurityContext. Pod will not be able to write to the volume."
fi

# 2. Check Memory Limit
MEM_LIMIT=$(kubectl get deploy data-analyzer -n data-processing -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
if [ "$MEM_LIMIT" != "40Mi" ]; then
    echo "[PASS] Memory limit adjusted or removed to prevent OOMKilled."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Memory limit is still 40Mi (will cause OOMKilled during the memory allocation test)."
fi

# 3. Check RoleBinding Target
RB_SUBJECT=$(kubectl get rolebinding analyzer-binding -n data-processing -o jsonpath='{.subjects[0].name}' 2>/dev/null)
if [ "$RB_SUBJECT" == "analyzer-sa" ]; then
    echo "[PASS] RoleBinding corrected to point to 'analyzer-sa'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] RoleBinding is pointing to '$RB_SUBJECT' instead of 'analyzer-sa'."
fi

# 4. End-to-end status check
POD_NAME=$(kubectl get pods -n data-processing -l app=analyzer -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    POD_STATUS=$(kubectl get pod "$POD_NAME" -n data-processing -o jsonpath='{.status.phase}')
    LOGS=$(kubectl logs "$POD_NAME" -n data-processing 2>/dev/null | tail -n 2)
    
    if echo "$LOGS" | grep -q "SUCCESS"; then
        echo "[PASS] Pod is running and all scripts report SUCCESS."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] Pod script has not completed successfully. Logs: $LOGS"
    fi
else
    echo "[FAIL] Deployment pod not found."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi