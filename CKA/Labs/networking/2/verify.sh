#!/bin/bash
set -euo pipefail

echo "Verifying Scenario 2..."
ERRORS=0

# Helper to check if a specific policy allows expected traffic.
# This relies on checking JSON output for specific port/namespace selectors.

FRONT_INGRESS=$(kubectl get netpol -n sec-front -o jsonpath='{.items[*].spec.ingress[*].from[*].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}')
if [[ "$FRONT_INGRESS" == *"ingress-nginx"* ]]; then
  echo "[PASS] sec-front allows ingress from ingress-nginx."
else
  echo "[FAIL] sec-front is missing correct ingress rules from ingress-nginx."
  ERRORS=$((ERRORS+1))
fi

FRONT_EGRESS_PORT=$(kubectl get netpol -n sec-front -o jsonpath='{.items[*].spec.egress[*].ports[*].port}')
if [[ "$FRONT_EGRESS_PORT" == *"8080"* ]]; then
  echo "[PASS] sec-front allows egress on port 8080."
else
  echo "[FAIL] sec-front missing egress rule for port 8080."
  ERRORS=$((ERRORS+1))
fi

BACK_INGRESS_NS=$(kubectl get netpol -n sec-back -o jsonpath='{.items[*].spec.ingress[*].from[*].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}')
if [[ "$BACK_INGRESS_NS" == *"sec-front"* ]]; then
  echo "[PASS] sec-back allows ingress from sec-front."
else
  echo "[FAIL] sec-back missing ingress rule from sec-front."
  ERRORS=$((ERRORS+1))
fi

BACK_EGRESS_PORT=$(kubectl get netpol -n sec-back -o jsonpath='{.items[*].spec.egress[*].ports[*].port}')
if [[ "$BACK_EGRESS_PORT" == *"5432"* ]]; then
  echo "[PASS] sec-back allows egress on port 5432."
else
  echo "[FAIL] sec-back missing egress rule for port 5432."
  ERRORS=$((ERRORS+1))
fi

DB_INGRESS_NS=$(kubectl get netpol -n sec-db -o jsonpath='{.items[*].spec.ingress[*].from[*].namespaceSelector.matchLabels.kubernetes\.io/metadata\.name}')
if [[ "$DB_INGRESS_NS" == *"sec-back"* ]]; then
  echo "[PASS] sec-db allows ingress from sec-back."
else
  echo "[FAIL] sec-db missing ingress rule from sec-back."
  ERRORS=$((ERRORS+1))
fi

if [ "$ERRORS" -eq 0 ]; then
  echo "Scenario 2 SUCCESS"
  exit 0
else
  echo "Scenario 2 FAILED with $ERRORS errors."
  exit 1
fi