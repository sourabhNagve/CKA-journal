#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check legacy-worker NodeName bypass
NODE_NAME_FIELD=$(kubectl get pod legacy-worker -n pipeline-ns -o jsonpath='{.spec.nodeName}' 2>/dev/null)
NODE_SELECTOR=$(kubectl get pod legacy-worker -n pipeline-ns -o jsonpath='{.spec.nodeSelector}' 2>/dev/null)

if [ -n "$NODE_NAME_FIELD" ] && [ -z "$NODE_SELECTOR" ]; then
    echo "[PASS] legacy-worker successfully bypassed the scheduler using nodeName."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] legacy-worker is not using nodeName, or is improperly using nodeSelector."
fi

# 2. Check legacy-worker Probes
LIVENESS_CMD=$(kubectl get pod legacy-worker -n pipeline-ns -o jsonpath='{.spec.containers[0].livenessProbe.exec.command[1]}' 2>/dev/null)
READINESS_PORT=$(kubectl get pod legacy-worker -n pipeline-ns -o jsonpath='{.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)

if [[ "$LIVENESS_CMD" == *"/usr/share/nginx/html/index.html"* ]] && [[ "$READINESS_PORT" == "80" ]]; then
    echo "[PASS] Liveness (exec) and Readiness (httpGet) probes are correctly configured."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Probes are missing or misconfigured on legacy-worker."
fi

# 3. Check smart-cache Node Affinity
NODE_AFFINITY=$(kubectl get deploy smart-cache -n pipeline-ns -o jsonpath='{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}' 2>/dev/null)

if [[ "$NODE_AFFINITY" == "tier" ]]; then
    echo "[PASS] smart-cache successfully configured with required Node Affinity."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Node Affinity is missing or incorrectly structured."
fi

# 4. Check smart-cache Pod Anti-Affinity
ANTI_AFFINITY_KEY=$(kubectl get deploy smart-cache -n pipeline-ns -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}' 2>/dev/null)

if [[ "$ANTI_AFFINITY_KEY" == "kubernetes.io/hostname" ]]; then
    echo "[PASS] smart-cache successfully configured with strict Pod Anti-Affinity."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Pod Anti-Affinity is missing or topologyKey is incorrect."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi