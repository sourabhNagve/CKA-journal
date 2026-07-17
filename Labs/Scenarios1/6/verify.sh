#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if the Pod was recreated with the correct environment variable
ENV_VAR=$(kubectl get pod report-generator -n legacy-ops -o jsonpath='{.spec.containers[0].env[?(@.name=="API_VERSION")].value}' 2>/dev/null)
if [ "$ENV_VAR" == "v2" ]; then
    echo "[PASS] Environment variable API_VERSION=v2 added to report-generator pod."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Pod is missing the API_VERSION=v2 environment variable (or pod does not exist)."
fi

# 2. Check if the Service is NodePort 32000
SVC_TYPE=$(kubectl get svc report-svc -n legacy-ops -o jsonpath='{.spec.type}' 2>/dev/null)
SVC_PORT=$(kubectl get svc report-svc -n legacy-ops -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ "$SVC_TYPE" == "NodePort" ] && [ "$SVC_PORT" == "32000" ]; then
    echo "[PASS] report-svc configured as NodePort on port 32000."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] report-svc is not properly configured. Type: $SVC_TYPE, NodePort: $SVC_PORT."
fi

# 3. Check Network Connectivity (Egress to API & DNS)
# Since the pod loops and sleeps on success, we check if it's Running and stable.
# To be 100% sure, we will exec into it and test the connection directly.
POD_STATUS=$(kubectl get pod report-generator -n legacy-ops -o jsonpath='{.status.phase}' 2>/dev/null)

if [ "$POD_STATUS" == "Running" ]; then
    EXEC_RESULT=$(kubectl exec report-generator -n legacy-ops -- curl -s -m 3 api-svc.internal-api.svc.cluster.local 2>/dev/null)
    
    if echo "$EXEC_RESULT" | grep -q "Welcome to nginx!"; then
        echo "[PASS] Pod successfully resolves DNS and communicates with api-svc."
        SCORE=$((SCORE+2)) # Worth 2 points because it involves 2 Egress rules (DNS + HTTP)
    else
        echo "[FAIL] Pod is Running but cannot reach api-svc. (Check Egress NetworkPolicy for HTTP/DNS)."
    fi
else
    echo "[FAIL] Pod is not in Running state (Current: $POD_STATUS). It is likely still crashing due to network failures."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi