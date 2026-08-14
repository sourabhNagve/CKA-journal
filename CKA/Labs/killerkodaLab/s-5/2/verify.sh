#!/bin/bash

SCORE=0
MAX_SCORE=5

echo "Running automated verification..."

# 1. Check ServiceAccount
if kubectl get sa vault-sa -n secure-vault >/dev/null 2>&1; then
    echo "[PASS] ServiceAccount 'vault-sa' exists."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] ServiceAccount 'vault-sa' not found."
fi

# 2. Check Pod Configuration (InitContainer & ServiceAccount)
POD_SA=$(kubectl get pod vault-backend -n secure-vault -o jsonpath='{.spec.serviceAccountName}' 2>/dev/null)
INIT_CONTAINER=$(kubectl get pod vault-backend -n secure-vault -o jsonpath='{.spec.initContainers[0].name}' 2>/dev/null)

if [[ "$POD_SA" == "vault-sa" ]] && [[ "$INIT_CONTAINER" == "setup-vault" ]]; then
    echo "[PASS] Pod uses correct ServiceAccount and contains the InitContainer."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Pod is missing the ServiceAccount assignment or InitContainer."
fi

# 3. Check SecurityContext (User ID and Capabilities)
RUN_AS_USER=$(kubectl get pod vault-backend -n secure-vault -o jsonpath='{.spec.containers[0].securityContext.runAsUser}' 2>/dev/null)
CAP_DROP=$(kubectl get pod vault-backend -n secure-vault -o jsonpath='{.spec.containers[0].securityContext.capabilities.drop[0]}' 2>/dev/null)
CAP_ADD=$(kubectl get pod vault-backend -n secure-vault -o jsonpath='{.spec.containers[0].securityContext.capabilities.add[0]}' 2>/dev/null)

if [[ "$RUN_AS_USER" == "1000" ]] && [[ "$CAP_DROP" == "ALL" ]] && [[ "$CAP_ADD" == "NET_BIND_SERVICE" ]]; then
    echo "[PASS] Strict SecurityContext applied successfully (runAsUser and Capabilities)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] SecurityContext is incorrect or missing."
fi

# 4. Check Gateway Resource
GW_CLASS=$(kubectl get gateway vault-gateway -n secure-vault -o jsonpath='{.spec.gatewayClassName}' 2>/dev/null)
if [[ "$GW_CLASS" == "internal-gw-class" ]]; then
    echo "[PASS] Gateway 'vault-gateway' correctly references 'internal-gw-class'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Gateway is missing or does not reference 'internal-gw-class'."
fi

# 5. Check HTTPRoute Resource
ROUTE_PATH=$(kubectl get httproute vault-route -n secure-vault -o jsonpath='{.spec.rules[0].matches[0].path.value}' 2>/dev/null)
ROUTE_BACKEND=$(kubectl get httproute vault-route -n secure-vault -o jsonpath='{.spec.rules[0].backendRefs[0].name}' 2>/dev/null)

if [[ "$ROUTE_PATH" == "/vault" ]] && [[ "$ROUTE_BACKEND" == "vault-svc" ]]; then
    echo "[PASS] HTTPRoute successfully configured to route '/vault' to 'vault-svc'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] HTTPRoute is missing or misconfigured."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi