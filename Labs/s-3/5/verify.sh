#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

# 1. Check Kube-Proxy Health
if kubectl get daemonset kube-proxy -n kube-system >/dev/null 2>&1; then
    KUBE_PROXY_CRASHING=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy -o jsonpath='{.items[*].status.containerStatuses[*].state.waiting.reason}' 2>/dev/null)
    if [[ "$KUBE_PROXY_CRASHING" == *"CrashLoopBackOff"* ]] || [[ "$KUBE_PROXY_CRASHING" == *"Error"* ]]; then
        echo "[FAIL] kube-proxy pods are still crashing. Check the ConfigMap syntax."
    else
        echo "[PASS] kube-proxy pods are Running normally."
        SCORE=$((SCORE+1))
    fi
else
    # Auto-pass if the cluster doesn't use kube-proxy (e.g. Cilium)
    echo "[PASS] kube-proxy not detected in this cluster, bypassing check."
    SCORE=$((SCORE+1))
fi

# 2. Check TopologySpreadConstraints
UNSATISFIABLE=$(kubectl get deploy payment-processor -n payments -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}' 2>/dev/null)
READY_REPLICAS=$(kubectl get deploy payment-processor -n payments -o jsonpath='{.status.readyReplicas}' 2>/dev/null)

if [ "$UNSATISFIABLE" == "ScheduleAnyway" ] && [ "$READY_REPLICAS" == "5" ]; then
    echo "[PASS] TopologySpreadConstraints updated to 'ScheduleAnyway' and all 5 replicas are Ready."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Deployment scheduling is still failing. Constraint is '$UNSATISFIABLE' and $READY_REPLICAS/5 replicas are Ready."
fi

# 3. Check Secret Type
SECRET_TYPE=$(kubectl get secret payment-tls -n payments -o jsonpath='{.type}' 2>/dev/null)
if [ "$SECRET_TYPE" == "kubernetes.io/tls" ]; then
    echo "[PASS] payment-tls Secret recreated with the correct type (kubernetes.io/tls)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] payment-tls Secret has the wrong type (Found: $SECRET_TYPE)."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi