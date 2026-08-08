#!/bin/bash
set -eo pipefail

NS="data-pipeline"
DEPLOY="data-processor"
HPA="data-processor-hpa"

echo "Verifying Scenario 3 constraints..."

# 1. Check Resource Requests (Prerequisite for HPA)
REQ_CPU=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
REQ_MEM=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')
if [ "$REQ_CPU" == "100m" ] && [ "$REQ_MEM" == "128Mi" ]; then
    echo "[PASS] Resource requests properly set for metrics baseline."
else
    echo "[FAIL] Resource requests incorrect or missing."
fi

# 2. Check HPA v2 Metrics & Replicas
if kubectl get hpa $HPA -n $NS > /dev/null 2>&1; then
    MIN_REP=$(kubectl get hpa $HPA -n $NS -o jsonpath='{.spec.minReplicas}')
    MAX_REP=$(kubectl get hpa $HPA -n $NS -o jsonpath='{.spec.maxReplicas}')
    
    CPU_TARGET=$(kubectl get hpa $HPA -n $NS -o jsonpath='{.spec.metrics[?(@.resource.name=="cpu")].resource.target.averageUtilization}')
    MEM_TARGET=$(kubectl get hpa $HPA -n $NS -o jsonpath='{.spec.metrics[?(@.resource.name=="memory")].resource.target.averageUtilization}')

    if [ "$MIN_REP" == "2" ] && [ "$MAX_REP" == "5" ] && [ "$CPU_TARGET" == "60" ] && [ "$MEM_TARGET" == "75" ]; then
        echo "[PASS] HPA v2 correctly configured for CPU (60%) and Memory (75%) with proper replica bounds."
    else
        echo "[FAIL] HPA configured improperly. (CPU: $CPU_TARGET, Mem: $MEM_TARGET, Min: $MIN_REP, Max: $MAX_REP)"
    fi
else
    echo "[FAIL] HPA $HPA not found."
fi

# 3. Check ConfigMap and envFrom
CM_FOUND=$(kubectl get cm app-settings -n $NS --ignore-not-found -o name)
if [ -n "$CM_FOUND" ]; then
    echo "[PASS] ConfigMap app-settings exists."
else
    echo "[FAIL] ConfigMap app-settings missing."
fi

ENV_FROM_CM=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}')
HARDCODED_ENV=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].env}' || echo "none")

if [ "$ENV_FROM_CM" == "app-settings" ]; then
    if [ "$HARDCODED_ENV" == "none" ] || [ -z "$HARDCODED_ENV" ]; then
        echo "[PASS] envFrom implemented and hardcoded env vars removed."
    else
        echo "[FAIL] envFrom found, but legacy hardcoded env array still exists."
    fi
else
    echo "[FAIL] envFrom is not pointing to app-settings."
fi