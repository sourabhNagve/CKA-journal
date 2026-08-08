#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

# Function to check API availability since it might be restarting during/after a restore
wait_for_api() {
  echo "Checking API server health..."
  for i in {1..30}; do
    if kubectl get --raw='/readyz' &> /dev/null; then
      return 0
    fi
    sleep 2
  done
  return 1
}

if ! wait_for_api; then
  echo "[FAIL] API Server is unreachable. The etcd restore likely failed and broke the control plane."
  echo "OVERALL: FAIL (0/3)"
  exit 1
fi

echo "[PASS] API Server is responsive."
SCORE=$((SCORE+1))

# 1. Check if the namespace reappeared
if kubectl get ns critical-data >/dev/null 2>&1; then
    echo "[PASS] Namespace 'critical-data' successfully recovered."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Namespace 'critical-data' not found. Data was not restored."
fi

# 2. Check if the deployment is recovered and running
DEPLOY_STATUS=$(kubectl get deploy db-backend -n critical-data -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$DEPLOY_STATUS" == "1" ]; then
    echo "[PASS] Deployment 'db-backend' is recovered and Ready."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Deployment 'db-backend' is missing or not Ready (Current Ready: ${DEPLOY_STATUS:-0}/1)."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi