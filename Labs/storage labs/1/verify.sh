#!/bin/bash
set -eo pipefail

NS="finance-system"
DEPLOY="finance-api"

echo "Verifying Scenario 1 constraints..."

# 1. Check Max Unavailable
MAX_UNAVAILABLE=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}')
if [ "$MAX_UNAVAILABLE" == "0" ] || [ "$MAX_UNAVAILABLE" == "0%" ]; then
    echo "[PASS] Strategy maxUnavailable is 0."
else
    echo "[FAIL] Strategy maxUnavailable is not 0 (Found: $MAX_UNAVAILABLE)."
fi

# 2. Check Node Affinity
AFFINITY_KEY=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}')
AFFINITY_VAL=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]}')
if [ "$AFFINITY_KEY" == "tier" ] && [ "$AFFINITY_VAL" == "secure" ]; then
    echo "[PASS] Node affinity correctly configured for tier=secure."
else
    echo "[FAIL] Node affinity incorrect or missing."
fi

# 3. Check Tolerations
TOLERATION_KEY=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="security-level")].key}')
TOLERATION_EFFECT=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="security-level")].effect}')
if [ "$TOLERATION_KEY" == "security-level" ] && [ "$TOLERATION_EFFECT" == "NoSchedule" ]; then
    echo "[PASS] Toleration for security-level=high:NoSchedule found."
else
    echo "[FAIL] Toleration missing or incorrectly configured."
fi

# 4. Check Resources
REQ_CPU=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
REQ_MEM=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
LIM_CPU=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}')
LIM_MEM=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')

if [ "$REQ_CPU" == "200m" ] && [ "$REQ_MEM" == "256Mi" ] && [ "$LIM_CPU" == "500m" ] && [ "$LIM_MEM" == "512Mi" ]; then
    echo "[PASS] Resources correctly bounded."
else
    echo "[FAIL] Resource boundaries are incorrect."
fi