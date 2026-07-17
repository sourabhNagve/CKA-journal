#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if CronJob is unsuspended
SUSPENDED=$(kubectl get cronjob db-backup -n db-ops -o jsonpath='{.spec.suspend}' 2>/dev/null)
if [ "$SUSPENDED" == "false" ]; then
    echo "[PASS] CronJob is active (suspend: false)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] CronJob is still suspended."
fi

# 2. Check if PVC is Bound
PVC_STATUS=$(kubectl get pvc backup-pvc -n db-ops -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" == "Bound" ]; then
    echo "[PASS] PVC 'backup-pvc' is Bound."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] PVC 'backup-pvc' is not Bound. Current status: $PVC_STATUS"
fi

# 3. Check Cross-Namespace RBAC (Can backup-sa exec into finance-system pods?)
CAN_EXEC=$(kubectl auth can-i create pods --subresource=exec -n finance-system --as=system:serviceaccount:db-ops:backup-sa 2>/dev/null)
CAN_GET=$(kubectl auth can-i get pods -n finance-system --as=system:serviceaccount:db-ops:backup-sa 2>/dev/null)

if [ "$CAN_EXEC" == "yes" ] && [ "$CAN_GET" == "yes" ]; then
    echo "[PASS] ServiceAccount 'backup-sa' has the correct cross-namespace RBAC permissions."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] ServiceAccount 'backup-sa' lacks required RBAC permissions in 'finance-system'. Exec: $CAN_EXEC, Get: $CAN_GET."
fi

# 4. End-to-End Test: Create a manual Job from the CronJob to verify execution
echo "Running an end-to-end test job..."
kubectl create job test-backup-job --from=cronjob/db-backup -n db-ops >/dev/null 2>&1

# Wait for the job to complete or fail
sleep 15
JOB_STATUS=$(kubectl get job test-backup-job -n db-ops -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null)

if [ "$JOB_STATUS" == "True" ]; then
    echo "[PASS] End-to-End Backup Job executed successfully."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] End-to-End Backup Job failed or timed out."
    # Output logs for debugging
    POD_NAME=$(kubectl get pods -n db-ops -l job-name=test-backup-job -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$POD_NAME" ]; then
        echo "--> Logs from failing pod:"
        kubectl logs $POD_NAME -n db-ops
    fi
fi

# Cleanup test job
kubectl delete job test-backup-job -n db-ops >/dev/null 2>&1

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi