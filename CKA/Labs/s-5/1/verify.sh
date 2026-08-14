#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification for Round 3..."

# ==========================================
# Question 1 Verification
# ==========================================
PVC_BOUND_TO=$(kubectl get pvc db-data-pvc -n storage-ns -o jsonpath='{.spec.volumeName}' 2>/dev/null)
POD_VOLUME=$(kubectl get pod db-pod -n storage-ns -o jsonpath='{.spec.volumes[?(@.persistentVolumeClaim.claimName=="db-data-pvc")].name}' 2>/dev/null)

if [[ "$PVC_BOUND_TO" == "db-data-pv" ]] && [[ -n "$POD_VOLUME" ]]; then
    echo "[PASS] Q1: PVC strictly bound to db-data-pv and mounted to the pod."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Q1: PVC bound to wrong PV ($PVC_BOUND_TO) or Pod is missing the mount."
fi

# ==========================================
# Question 2 Verification
# ==========================================
INIT_CONTAINER=$(kubectl get pod boot-app -n frontend-ns -o jsonpath='{.spec.initContainers[0].name}' 2>/dev/null)
MAIN_CONTAINER=$(kubectl get pod boot-app -n frontend-ns -o jsonpath='{.spec.containers[0].name}' 2>/dev/null)
POD_STATUS=$(kubectl get pod boot-app -n frontend-ns -o jsonpath='{.status.phase}' 2>/dev/null)

if [[ "$INIT_CONTAINER" == "data-fetcher" ]] && [[ "$MAIN_CONTAINER" == "web-server" ]] && [[ "$POD_STATUS" == "Running" ]]; then
    echo "[PASS] Q2: InitContainer executed successfully and main pod is Running."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Q2: InitContainer missing or pod failed to reach Running state."
fi

# ==========================================
# Question 3 Verification
# ==========================================
STATIC_POD_EXISTS=$(kubectl get pods -A -o jsonpath='{.items[*].metadata.name}' | grep -o 'node-monitor')

if [ -n "$STATIC_POD_EXISTS" ]; then
    echo "[PASS] Q3: Static pod 'node-monitor' successfully created and detected by API."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Q3: Static pod not found. Did you place the YAML in the correct directory on the worker?"
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE) - MACHINE-LIKE PRECISION."
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE) - Analyze your errors."
    exit 1
fi