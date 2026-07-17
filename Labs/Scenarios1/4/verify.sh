#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

# 1. Check if backend-api pods are running (Secret mount fixed)
BACKEND_READY=$(kubectl get pods -n secure-corp -l tier=backend -o jsonpath='{.items[*].status.phase}' 2>/dev/null)
if echo "$BACKEND_READY" | grep -q "Running"; then
    echo "[PASS] backend-api pods are Running."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] backend-api pods are not Running (Fix the secret mount)."
fi

# 2. Check if frontend can talk to backend (Egress NetPol fixed)
# Using exec on the frontend pod to curl the backend service
FRONTEND_POD=$(kubectl get pods -n secure-corp -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$FRONTEND_POD" ]; then
    EXEC_RESULT=$(kubectl exec -n secure-corp "$FRONTEND_POD" -- curl -s -m 3 backend-svc 2>/dev/null)
    if echo "$EXEC_RESULT" | grep -q "Welcome to nginx!"; then
        echo "[PASS] frontend-app can successfully communicate with backend-svc."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] frontend-app cannot reach backend-svc. (Check Egress NetworkPolicy rules)."
    fi
else
    echo "[FAIL] frontend-app pod not found."
fi

# 3. Check if external clients can reach frontend (Ingress NetPol fixed)
# We test this by spinning up a temporary pod in the default namespace
echo "Testing cross-namespace Ingress to frontend-svc..."
EXT_RESULT=$(kubectl run test-ext-client --rm -i --image=curlimages/curl --restart=Never -- curl -s -m 3 frontend-svc.secure-corp.svc.cluster.local 2>/dev/null)
if echo "$EXT_RESULT" | grep -q "Welcome to nginx!"; then
    echo "[PASS] External pods can reach frontend-svc."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] External pods cannot reach frontend-svc. (Check Ingress NetworkPolicy rules on frontend-netpol)."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi