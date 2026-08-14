#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification..."

# 1. Check if Deployment has CPU requests configured (Fixes the HPA)
CPU_REQUEST=$(kubectl get deploy api-gateway -n edge-routing -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)
if [ "$CPU_REQUEST" == "100m" ]; then
    echo "[PASS] CPU request set to 100m. The HPA will now be able to calculate metrics."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] CPU request is missing or incorrect (Found: $CPU_REQUEST). HPA will remain in <unknown> state."
fi

# 2. Check if RBAC verbs were fixed
CAN_LIST=$(kubectl auth can-i list configmaps -n edge-routing --as=system:serviceaccount:edge-routing:gateway-sa 2>/dev/null)
CAN_DELETE=$(kubectl auth can-i delete configmaps -n edge-routing --as=system:serviceaccount:edge-routing:gateway-sa 2>/dev/null)

if [ "$CAN_LIST" == "yes" ] && [ "$CAN_DELETE" == "no" ]; then
    echo "[PASS] Role verbs corrected to principle of least privilege (get, list)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] RBAC Role verbs are incorrect. Expected list=yes, delete=no. Got list=$CAN_LIST, delete=$CAN_DELETE."
fi

# 3. Check if StartupProbe was fixed and Pod is Ready
POD_NAME=$(kubectl get pods -n edge-routing -l app=gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    # We allow up to 25 seconds for the pod to boot and pass its startup probe
    echo "Waiting up to 25 seconds for pod to complete boot sequence and pass probes..."
    POD_READY=false
    for i in {1..8}; do
        READY_STATUS=$(kubectl get pod "$POD_NAME" -n edge-routing -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$READY_STATUS" == "True" ]; then
            POD_READY=true
            break
        fi
        sleep 3
    done
    
    if [ "$POD_READY" = true ]; then
        echo "[PASS] Pod successfully survived the boot sequence (startupProbe fixed) and is Ready."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] Pod is still crashing or failing probes. Check the startupProbe timings (give it >15s)."
    fi
else
    echo "[FAIL] api-gateway pod not found."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi