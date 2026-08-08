#!/bin/bash
set -euo pipefail

echo "Verifying Scenario 1..."
ERRORS=0

# 1. Verify CoreDNS
COREDNS_CM=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}')
if echo "$COREDNS_CM" | grep -q "invalidplugin"; then
  echo "[FAIL] CoreDNS ConfigMap still contains 'invalidplugin'."
  ERRORS=$((ERRORS+1))
else
  echo "[PASS] CoreDNS ConfigMap is fixed."
fi

# 2. Verify api-v2 Service Endpoints
API_V2_ENDPOINTS=$(kubectl get endpoints api-v2 -n default -o jsonpath='{range .subsets[*]}{range .addresses[*]}{.ip}{"\n"}{end}{end}' | wc -l)
if [ "$API_V2_ENDPOINTS" -eq 0 ]; then
  echo "[FAIL] Service 'api-v2' has 0 endpoints. Label selector is likely still broken."
  ERRORS=$((ERRORS+1))
else
  echo "[PASS] Service 'api-v2' has active endpoints."
fi

# 3. Verify HTTPRoute weights and references
V1_WEIGHT=$(kubectl get httproute api-canary-route -n default -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="api-v1")].weight}')
V2_WEIGHT=$(kubectl get httproute api-canary-route -n default -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="api-v2")].weight}')

if [ "$V1_WEIGHT" == "70" ] && [ "$V2_WEIGHT" == "30" ]; then
  echo "[PASS] HTTPRoute traffic split is exactly 70/30 across valid backends."
else
  echo "[FAIL] HTTPRoute traffic split is incorrect. Found api-v1: ${V1_WEIGHT:-0}, api-v2: ${V2_WEIGHT:-0} (Expected 70/30)."
  ERRORS=$((ERRORS+1))
fi

if [ "$ERRORS" -eq 0 ]; then
  echo "Scenario 1 SUCCESS"
  exit 0
else
  echo "Scenario 1 FAILED with $ERRORS errors."
  exit 1
fi