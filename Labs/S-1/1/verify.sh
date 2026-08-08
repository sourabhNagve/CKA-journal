#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if Service selector is fixed
SVC_SELECTOR=$(kubectl get svc postgres-svc -n finance-db -o jsonpath='{.spec.selector.app}' 2>/dev/null)
if [ "$SVC_SELECTOR" == "postgres" ]; then
    echo "[PASS] Service selector corrected."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Service selector on 'postgres-svc' is incorrect."
fi

# 2. Check Namespace label or Network Policy adjustment
# The user can either label the finance-api namespace OR edit the NetworkPolicy
#!/bin/bash

# 1. Fetch ALL label values from the finance-api namespace as a space-separated string.
NS_LABEL_VALUES=$(kubectl get ns finance-api -o jsonpath='{.metadata.labels.*}' 2>/dev/null)

# 2. Fetch the raw matchLabels object (to check for empty/allow-all) AND just its values.
NP_NS_SELECTOR=$(kubectl get networkpolicy allow-api-to-db -n finance-db -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector.matchLabels}' 2>/dev/null)
NP_SELECTOR_VALUES=$(kubectl get networkpolicy allow-api-to-db -n finance-db -o jsonpath='{.spec.ingress[0].from[0].namespaceSelector.matchLabels.*}' 2>/dev/null)

# 3. First, check if the NetworkPolicy selector is completely empty or explicitly {} (Allow-All)
if [[ "$NP_NS_SELECTOR" == "{}" ]] || [[ -z "$NP_NS_SELECTOR" ]]; then
    echo "[PASS] Network isolation issue resolved (NetworkPolicy allows all namespaces)."
    SCORE=$((SCORE+1))
else
    # 4. Dynamic Check: Loop through whatever values the NetworkPolicy requires
    # and verify they exist within the namespace's label values.
    MATCH="true"
    for val in $NP_SELECTOR_VALUES; do
        if [[ ! " $NS_LABEL_VALUES " == *" $val "* ]]; then
            MATCH="false" # Found a required value that isn't on the namespace
            break
        fi
    done

    # 5. Evaluate the result
    if [[ "$MATCH" == "true" && -n "$NP_SELECTOR_VALUES" ]]; then
        echo "[PASS] Network isolation issue resolved (Labels match)."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] NetworkPolicy is still blocking traffic from finance-api namespace."
    fi
fi

# 3. Check if pod is running
# Give it a few seconds just in case it just transitioned
sleep 3
API_STATUS=$(kubectl get pods -n finance-api -l app=api-server -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$API_STATUS" == "Running" ]; then
    echo "[PASS] api-server pod is Running."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] api-server pod is not Running. Current status: $API_STATUS"
fi

# 4. Check RBAC
CAN_EXEC=$(kubectl auth can-i create pods  --subresource=exec -n finance-db --as=system:serviceaccount:finance-db:db-troubleshooter 2>/dev/null)
CAN_GET=$(kubectl auth can-i get pods -n finance-db --as=system:serviceaccount:finance-db:db-troubleshooter 2>/dev/null)
CAN_DELETE=$(kubectl auth can-i delete pods -n finance-db --as=system:serviceaccount:finance-db:db-troubleshooter 2>/dev/null)

if [ "$CAN_EXEC" == "yes" ] && [ "$CAN_GET" == "yes" ] && [ "$CAN_DELETE" == "no" ]; then
    echo "[PASS] RBAC configured correctly for db-troubleshooter."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] RBAC not configured correctly. Exec: $CAN_EXEC, Get: $CAN_GET, Delete: $CAN_DELETE (Delete should be 'no')."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi