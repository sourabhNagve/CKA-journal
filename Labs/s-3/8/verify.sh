#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if API Server is back online
if kubectl get --raw='/readyz' &> /dev/null; then
    echo "[PASS] kube-apiserver fixed! API Server is responsive."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] API Server is still down. Check /etc/kubernetes/manifests/kube-apiserver.yaml for syntax errors (look at authorization-mode)."
    echo "OVERALL: FAIL ($SCORE/4)"
    exit 1
fi

# 2. Check DaemonSet Control Plane Tolerations
DS_TOLERATIONS=$(kubectl get daemonset fluentd-logger -n observability -o jsonpath='{.spec.template.spec.tolerations}' 2>/dev/null)
if [[ "$DS_TOLERATIONS" == *"control-plane"* ]] || [[ "$DS_TOLERATIONS" == *"master"* ]]; then
    echo "[PASS] DaemonSet tolerations added. It can now schedule on the control-plane node."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] DaemonSet is missing tolerations for the control-plane node. Pods will not deploy everywhere."
fi

# 3. Check HostPath Volume Typo Fix
HOST_PATH=$(kubectl get daemonset fluentd-logger -n observability -o jsonpath='{.spec.template.spec.volumes[?(@.name=="varlog")].hostPath.path}' 2>/dev/null)
if [ "$HOST_PATH" == "/var/log/containers" ]; then
    echo "[PASS] DaemonSet hostPath volume corrected to /var/log/containers."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] DaemonSet hostPath is still incorrect (Found: $HOST_PATH)."
fi

# 4. Check End-to-End Status (Are pods running on all nodes?)
DESIRED=$(kubectl get daemonset fluentd-logger -n observability -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)
READY=$(kubectl get daemonset fluentd-logger -n observability -o jsonpath='{.status.numberReady}' 2>/dev/null)
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)

if [ "$DESIRED" == "$NODE_COUNT" ] && [ "$READY" == "$DESIRED" ] && [ "$READY" -gt 0 ]; then
    echo "[PASS] All $READY pods are Running successfully across all nodes."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Not all pods are ready. Nodes in cluster: $NODE_COUNT. Desired Pods: ${DESIRED:-0}. Ready Pods: ${READY:-0}."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi