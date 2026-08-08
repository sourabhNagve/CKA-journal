#!/bin/bash
set -euo pipefail

echo "Verifying Scenario 3..."
ERRORS=0

# 1. Check Ingress Rewrite Annotation
REWRITE=$(kubectl get ingress payments-ingress -n finance -o jsonpath='{.metadata.annotations.nginx\.ingress\.kubernetes\.io/rewrite-target}')
if [ "$REWRITE" == "/\$2" ]; then
  echo "[PASS] Ingress rewrite-target is correct (/\$2)."
else
  echo "[FAIL] Ingress rewrite-target is incorrect. Found: $REWRITE"
  ERRORS=$((ERRORS+1))
fi

# 2. Check TLS Configuration
TLS_HOST=$(kubectl get ingress payments-ingress -n finance -o jsonpath='{.spec.tls[0].hosts[0]}')
TLS_SECRET=$(kubectl get ingress payments-ingress -n finance -o jsonpath='{.spec.tls[0].secretName}')
if [ "$TLS_HOST" == "payments.acme.corp" ] && [ "$TLS_SECRET" == "payments-tls" ]; then
  echo "[PASS] Ingress TLS is correctly configured."
else
  echo "[FAIL] Ingress TLS is missing or incorrect."
  ERRORS=$((ERRORS+1))
fi

# 3. Check Service TargetPort
TARGET_PORT=$(kubectl get svc payments-svc -n finance -o jsonpath='{.spec.ports[0].targetPort}')
if [ "$TARGET_PORT" == "8080" ]; then
  echo "[PASS] Service targetPort correctly maps to 8080."
else
  echo "[FAIL] Service targetPort is $TARGET_PORT (Expected 8080)."
  ERRORS=$((ERRORS+1))
fi

# 4. Check NodePort Pinning
NODE_PORT=$(kubectl get svc payments-svc -n finance -o jsonpath='{.spec.ports[0].nodePort}')
if [ "$NODE_PORT" == "32123" ]; then
  echo "[PASS] Service nodePort explicitly set to 32123."
else
  echo "[FAIL] Service nodePort is $NODE_PORT (Expected 32123)."
  ERRORS=$((ERRORS+1))
fi

if [ "$ERRORS" -eq 0 ]; then
  echo "Scenario 3 SUCCESS"
  exit 0
else
  echo "Scenario 3 FAILED with $ERRORS errors."
  exit 1
fi