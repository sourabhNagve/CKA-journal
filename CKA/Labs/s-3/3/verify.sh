#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if token mounting is fixed
AUTOMOUNT=$(kubectl get deploy secret-auditor -n security-audit -o jsonpath='{.spec.template.spec.automountServiceAccountToken}' 2>/dev/null)
if [ "$AUTOMOUNT" == "true" ] || [ -z "$AUTOMOUNT" ]; then
    echo "[PASS] automountServiceAccountToken is enabled (or removed, defaulting to true)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] automountServiceAccountToken is still set to false. The pod cannot mount its token."
fi

# 2. Check NetworkPolicy Egress Rule
EGRESS_PORTS=$(kubectl get netpol audit-netpol -n security-audit -o jsonpath='{.spec.egress[*].ports[*].port}' 2>/dev/null)
if echo "$EGRESS_PORTS" | grep -q "443"; then
    echo "[PASS] NetworkPolicy correctly allows Egress on port 443."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] NetworkPolicy 'audit-netpol' does not explicitly allow Egress on port 443. Traffic to API server is blocked."
fi

# 3. Check RoleBinding Target
RB_SUBJECT=$(kubectl get rolebinding auditor-binding -n security-audit -o jsonpath='{.subjects[0].name}' 2>/dev/null)
if [ "$RB_SUBJECT" == "auditor-sa" ]; then
    echo "[PASS] RoleBinding 'auditor-binding' corrected to target 'auditor-sa'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] RoleBinding is targeting the wrong ServiceAccount (Found: $RB_SUBJECT)."
fi

# 4. Check End-to-End Status via Logs
POD_NAME=$(kubectl get pods -n security-audit -l app=auditor -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    echo "Waiting up to 15 seconds to evaluate pod logs..."
    SUCCESS=false
    for i in {1..5}; do
        LOGS=$(kubectl logs "$POD_NAME" -n security-audit 2>/dev/null | tail -n 2)
        if echo "$LOGS" | grep -q "SUCCESS"; then
            SUCCESS=true
            break
        fi
        sleep 3
    done
    
    if [ "$SUCCESS" = true ]; then
        echo "[PASS] Pod successfully authenticated and authorized with the API server."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] Pod is still failing. Recent logs:"
        echo "$LOGS"
    fi
else
    echo "[FAIL] secret-auditor pod not found."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi