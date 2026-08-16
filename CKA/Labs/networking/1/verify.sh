#!/bin/bash
# verify-scenario.sh
# Verification script for "The Gateway API Canary & DNS Blackhole"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "🔍 Starting Verification..."
echo "--------------------------------------------------------"

SCORE=0
TOTAL_CHECKS=4

# ---------------------------------------------------------
# Check 1: CoreDNS ConfigMap
# ---------------------------------------------------------
echo -n "1. Checking CoreDNS ConfigMap... "
CM_CONTENT=$(kubectl get cm coredns -n kube-system -o jsonpath='{.data.Corefile}' 2>/dev/null)

if echo "$CM_CONTENT" | grep -q "dns_blackhole_plugin_invalid"; then
  echo -e "${RED}FAILED${NC}"
  echo -e "   ↳ The invalid 'dns_blackhole_plugin_invalid' block is still present in the ConfigMap."
else
  echo -e "${GREEN}PASSED${NC}"
  SCORE=$((SCORE + 1))
fi

# ---------------------------------------------------------
# Check 2: CoreDNS Pod Health
# ---------------------------------------------------------
echo -n "2. Checking CoreDNS Pod Health... "
# Wait a few seconds in case they just restarted them
sleep 2 

COREDNS_READY=$(kubectl get deploy coredns -n kube-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
COREDNS_DESIRED=$(kubectl get deploy coredns -n kube-system -o jsonpath='{.spec.replicas}' 2>/dev/null)

if [ -z "$COREDNS_READY" ] || [ "$COREDNS_READY" -ne "$COREDNS_DESIRED" ]; then
  echo -e "${RED}FAILED${NC}"
  echo -e "   ↳ CoreDNS pods are not fully running. Expected $COREDNS_DESIRED, Ready: ${COREDNS_READY:-0}."
  echo -e "   ↳ Did the candidate forget to run: kubectl rollout restart deployment coredns -n kube-system?"
else
  echo -e "${GREEN}PASSED${NC}"
  SCORE=$((SCORE + 1))
fi

# ---------------------------------------------------------
# Check 3: api-v2 Service Endpoints
# ---------------------------------------------------------
echo -n "3. Checking api-v2 Service Endpoints... "
EPS=$(kubectl get endpoints api-v2 -n default -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)

if [ -z "$EPS" ]; then
  echo -e "${RED}FAILED${NC}"
  echo -e "   ↳ No active endpoints found for 'api-v2'. The label selector mismatch likely still exists."
else
  echo -e "${GREEN}PASSED${NC}"
  SCORE=$((SCORE + 1))
fi

# ---------------------------------------------------------
# Check 4: Gateway API HTTPRoute Routing
# ---------------------------------------------------------
echo "4. Checking Gateway API HTTPRoute rules... "

# Extract backend weights and names
WEIGHT_V1=$(kubectl get httproute api-canary-route -n default -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="api-v1")].weight}' 2>/dev/null)
BACKEND_V2=$(kubectl get httproute api-canary-route -n default -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="api-v2")].name}' 2>/dev/null)
WEIGHT_V2=$(kubectl get httproute api-canary-route -n default -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="api-v2")].weight}' 2>/dev/null)

ROUTE_PASSED=true

if [ "$WEIGHT_V1" != "70" ]; then
  echo -e "   ↳ ${RED}FAILED:${NC} api-v1 weight is '${WEIGHT_V1:-not set}'. Expected: 70."
  ROUTE_PASSED=false
fi

if [ -z "$BACKEND_V2" ]; then
  echo -e "   ↳ ${RED}FAILED:${NC} api-v2 backend reference not found. The typo 'api-v2-typo' might still exist."
  ROUTE_PASSED=false
elif [ "$WEIGHT_V2" != "30" ]; then
  echo -e "   ↳ ${RED}FAILED:${NC} api-v2 weight is '${WEIGHT_V2}'. Expected: 30."
  ROUTE_PASSED=false
fi

if $ROUTE_PASSED; then
  echo -e "   ↳ ${GREEN}PASSED:${NC} HTTPRoute is correctly configured (api-v1=70, api-v2=30)."
  SCORE=$((SCORE + 1))
fi

# ---------------------------------------------------------
# Final Results
# ---------------------------------------------------------
echo "--------------------------------------------------------"
if [ "$SCORE" -eq "$TOTAL_CHECKS" ]; then
  echo -e "🎉 ${GREEN}ALL CHECKS PASSED! ($SCORE/$TOTAL_CHECKS)${NC}"
  echo "The candidate successfully restored cluster resolution and fixed the canary rollout."
else
  echo -e "⚠️  ${YELLOW}SCENARIO INCOMPLETE ($SCORE/$TOTAL_CHECKS CHECKS PASSED)${NC}"
  echo "Please review the failed checks above."
fi