#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check Rollback (Image should be back to stable)
IMAGE=$(kubectl get deploy finance-api -n accounting -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$IMAGE" == "nginx:1.21-alpine" ]]; then
    echo "[PASS] Deployment successfully rolled back to stable image."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Deployment is running image '$IMAGE'. Rollback not performed correctly."
fi

# 2. Check Data Injection (Secret Env and ConfigMap Volume)
HAS_ENV=$(kubectl get deploy finance-api -n accounting -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].secretRef.name}' 2>/dev/null)
HAS_VOL=$(kubectl get deploy finance-api -n accounting -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}' 2>/dev/null)

if [[ "$HAS_ENV" == "db-credentials" ]] && [[ "$HAS_VOL" == "app-config" ]]; then
    echo "[PASS] Secret and ConfigMap correctly injected into the deployment."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Missing Secret env variables or ConfigMap volume mount."
fi

# 3. Check Resource Limits for HPA
REQ_CPU=$(kubectl get deploy finance-api -n accounting -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [[ "$REQ_CPU" == "100m" ]]; then
    echo "[PASS] CPU requests added successfully. HPA will now function."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] CPU requests not found or incorrect. HPA will remain in <unknown> state."
fi

# 4. Check JSONPath output file
if [ -f "/opt/finance-pods.txt" ] && grep -q "finance-api" "/opt/finance-pods.txt"; then
    echo "[PASS] JSONPath output file found and contains pod names."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] /opt/finance-pods.txt is missing or incorrect."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi