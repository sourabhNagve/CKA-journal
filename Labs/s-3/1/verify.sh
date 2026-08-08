#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

# 1. Check if kube-scheduler is Running
SCHEDULER_STATUS=$(kubectl get pods -n kube-system -l component=kube-scheduler -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$SCHEDULER_STATUS" == "Running" ]; then
    echo "[PASS] kube-scheduler is Running. The manifest typo was corrected."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] kube-scheduler is not Running (Current: ${SCHEDULER_STATUS:-NotFound}). Check /etc/kubernetes/manifests/kube-scheduler.yaml."
fi

# 2. Check if the audit-logger static pod is Running
AUDIT_STATUS=$(kubectl get pods -n kube-system -l component=audit-logger -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
# Static pods sometimes don't have standard labels unless specified, so we fallback to a name match:
if [ -z "$AUDIT_STATUS" ]; then
    AUDIT_STATUS=$(kubectl get pods -n kube-system | grep audit-logger | awk '{print $3}')
fi

if [ "$AUDIT_STATUS" == "Running" ]; then
    echo "[PASS] audit-logger static pod is Running. Image typo corrected."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] audit-logger static pod is not Running (Current: ${AUDIT_STATUS:-NotFound}). Check /etc/kubernetes/manifests/audit-logger.yaml."
fi

# 3. Check if the web-front deployment successfully scheduled
READY_REPLICAS=$(kubectl get deploy web-front -n default -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY_REPLICAS" == "2" ]; then
    echo "[PASS] 'web-front' Deployment has scheduled successfully! The scheduler is doing its job."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] 'web-front' Deployment is still Pending or not fully ready. Replicas ready: ${READY_REPLICAS:-0}/2."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi