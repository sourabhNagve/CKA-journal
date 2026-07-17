#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

# 1. Check if ecommerce-app pod is Ready (Readiness Probe fixed)
POD_READY=$(kubectl get pods -n ecommerce -l app=ecommerce-app -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
if [ "$POD_READY" == "True" ]; then
    echo "[PASS] ecommerce-app Pod is Ready (Readiness probe corrected)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] ecommerce-app Pod is not Ready. (Check readiness probe configuration)."
fi

# 2. Check if Ingress backend port is corrected
INGRESS_PORT=$(kubectl get ingress ecommerce-ingress -n ecommerce -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.port.number}' 2>/dev/null)
if [ "$INGRESS_PORT" == "80" ]; then
    echo "[PASS] Ingress backend port is correctly set to 80."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Ingress backend port is incorrect. Found: $INGRESS_PORT (Expected: 80)."
fi

# 3. Check if DaemonSet is scheduled on Control Plane (Toleration added)
# We count total nodes vs desired scheduled for the DaemonSet
TOTAL_NODES=$(kubectl get nodes -o name | wc -l)
DS_DESIRED=$(kubectl get daemonset node-defender -n security-ops -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null)

if [ -n "$DS_DESIRED" ] && [ "$DS_DESIRED" -ge "$TOTAL_NODES" ]; then
    echo "[PASS] DaemonSet is configured to run on all nodes (Control Plane toleration added)."
    SCORE=$((SCORE+1))
else
    # Fallback check just in case total nodes calculation is weird: check tolerations directly
    TOLERATIONS=$(kubectl get ds node-defender -n security-ops -o jsonpath='{.spec.template.spec.tolerations}' 2>/dev/null)
    if echo "$TOLERATIONS" | grep -q "node-role.kubernetes.io/control-plane" || echo "$TOLERATIONS" | grep -q 'operator":"Exists"'; then
        echo "[PASS] DaemonSet has the necessary tolerations to schedule on the Control Plane."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] DaemonSet is not scheduled on all nodes. Desired: $DS_DESIRED, Total Nodes: $TOTAL_NODES. (Check Taints/Tolerations)."
    fi
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi