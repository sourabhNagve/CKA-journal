#!/bin/bash
set -eo pipefail

NS="etl-jobs"
DEPLOY="data-sync"
SA="etl-runner"

echo "Verifying Scenario 5 constraints..."

# 1. Check ServiceAccount Existence
if kubectl get sa $SA -n $NS > /dev/null 2>&1; then
    echo "[PASS] ServiceAccount $SA exists."
else
    echo "[FAIL] ServiceAccount $SA not found."
fi

# 2. Check SA Integration and Automount Token
SA_NAME=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.serviceAccountName}")
AUTOMOUNT=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.automountServiceAccountToken}")

if [ "$SA_NAME" == "$SA" ] && [ "$AUTOMOUNT" == "false" ]; then
    echo "[PASS] Zero-Trust configured: SA is $SA and automountServiceAccountToken is false."
else
    echo "[FAIL] Zero-Trust failed. (SA: $SA_NAME, Automount: $AUTOMOUNT)."
fi

# 3. Check Secret Prefixing in envFrom
PREFIX_1=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.containers[0].envFrom[?(@.secretRef.name=='db-creds-primary')].prefix}")
PREFIX_2=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.containers[0].envFrom[?(@.secretRef.name=='db-creds-replica')].prefix}")

if [ "$PREFIX_1" == "PRI_" ] && [ "$PREFIX_2" == "REP_" ]; then
    echo "[PASS] Both secrets injected via envFrom with correct PRI_ and REP_ prefixes."
else
    echo "[FAIL] Secret prefixing incorrect or missing. (Primary Prefix: $PREFIX_1, Replica Prefix: $PREFIX_2)."
fi

# 4. Check Hardcoded Env Removed
HARDCODED=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.containers[0].env}" || echo "none")
if [ "$HARDCODED" == "none" ] || [ -z "$HARDCODED" ]; then
    echo "[PASS] Insecure hardcoded env vars removed."
else
    echo "[FAIL] Hardcoded env vars still present."
fi