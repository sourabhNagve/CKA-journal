#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

# 1. Test Ingress: Frontend -> Backend:8080
FRONTEND_POD=$(kubectl get pod -n secure-app -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
INSPECT_INGRESS=$(kubectl exec -n secure-app "$FRONTEND_POD" -- nc -zv -w 3 backend.secure-app.svc.cluster.local 8080 2>&1)

if echo "$INSPECT_INGRESS" | grep -q -iE "open|succeeded"; then
    echo "[PASS] Frontend can successfully reach Backend on port 8080."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Frontend failed to reach Backend on port 8080."
fi

# 2. Test Egress: Backend -> DB:5432
BACKEND_POD=$(kubectl get pod -n secure-app -l app=backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
INSPECT_EGRESS=$(kubectl exec -n secure-app "$BACKEND_POD" -- nc -zv -w 3 db-svc.database-ns.svc.cluster.local 5432 2>&1)

if echo "$INSPECT_EGRESS" | grep -q -iE "open|succeeded"; then
    echo "[PASS] Backend can successfully reach DB in database-ns on port 5432."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Backend failed to reach DB on port 5432. Check namespaceSelector and policyTypes."
fi

# 3. Test Isolation Integrity: Ensure Frontend cannot reach DB directly
UNAUTHORIZED_CHECK=$(kubectl exec -n secure-app "$FRONTEND_POD" -- nc -zv -w 2 db-svc.database-ns.svc.cluster.local 5432 2>&1)

if ! echo "$UNAUTHORIZED_CHECK" | grep -q -iE "open|succeeded"; then
    echo "[PASS] Network isolation intact (Frontend cannot reach DB directly)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Security policy leak: Frontend was able to reach DB directly!"
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi