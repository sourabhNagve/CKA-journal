#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check Node Labels
NODE_LABELS=$(kubectl get nodes -l tier=edge -o name 2>/dev/null)
if [ -n "$NODE_LABELS" ]; then
    echo "[PASS] At least one node is labeled with 'tier=edge'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] No nodes are labeled with 'tier=edge'."
fi

# 2. Check PodAntiAffinity configuration (Should be preferred, not required)
AFFINITY_TYPE=$(kubectl get deploy gateway-app -n edge-net -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity}' 2>/dev/null)
if echo "$AFFINITY_TYPE" | grep -q "preferredDuringSchedulingIgnoredDuringExecution"; then
    echo "[PASS] PodAntiAffinity successfully converted to 'preferredDuringSchedulingIgnoredDuringExecution'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] PodAntiAffinity is still set to 'requiredDuringSchedulingIgnoredDuringExecution' or is incorrectly formatted."
fi

# 3. Check Liveness Probe Port
PROBE_PORT=$(kubectl get deploy gateway-app -n edge-net -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.port}' 2>/dev/null)
if [ "$PROBE_PORT" == "80" ]; then
    echo "[PASS] Liveness probe port corrected to 80."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Liveness probe port is incorrect (Currently: $PROBE_PORT)."
fi

# 4. Check Ingress Backend Service Name
INGRESS_SVC=$(kubectl get ingress gateway-ingress -n edge-net -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null)
if [ "$INGRESS_SVC" == "gateway-svc" ]; then
    echo "[PASS] Ingress backend service name corrected."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Ingress backend service name is incorrect (Currently: $INGRESS_SVC)."
fi

# End to End Readiness check
READY_REPLICAS=$(kubectl get deploy gateway-app -n edge-net -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY_REPLICAS" == "3" ]; then
    echo "--> All 3 replicas are Running and Ready!"
else
    echo "--> Waiting for replicas to become Ready. (Currently: ${READY_REPLICAS:-0}/3)"
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi