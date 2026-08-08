#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification for the Final Boss..."

# 1. Check CoreDNS Health
DNS_READY=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)
if [ "$DNS_READY" == "true" ]; then
    echo "[PASS] CoreDNS ConfigMap fixed! DNS is resolving."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] CoreDNS is still crashing. Did you remove the syntax error from the ConfigMap?"
fi

# 2. Check PVC Binding
PVC_STATUS=$(kubectl get pvc data-pvc -n processing -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" == "Bound" ]; then
    echo "[PASS] PVC 'data-pvc' is Bound (Capacity mismatch fixed)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] PVC is in state: ${PVC_STATUS:-NotFound}. Ensure it requests exactly 2Gi to match the PV."
fi

# 3. Check Pod Scheduling & Status
POD_STATUS=$(kubectl get pods -n processing -l app=processor -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" == "Running" ]; then
    echo "[PASS] Pod 'data-processor' is Running (Toleration added and storage mounted)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Pod 'data-processor' is not Running (State: $POD_STATUS). Check tolerations and events."
fi

# 4. Check Service Routing (Logs)
if [ "$POD_STATUS" == "Running" ] && [ "$DNS_READY" == "true" ]; then
    sleep 5 # Wait a moment for the script loop to execute
    LOG_OUTPUT=$(kubectl logs deploy/data-processor -n processing | tail -n 5)
    if echo "$LOG_OUTPUT" | grep -q "Connected to Redis database successfully"; then
        echo "[PASS] Internal routing fixed! Data processor can reach Redis."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] Pod is running, but cannot connect to Redis. Check the Service selector."
    fi
else
    echo "[FAIL] Cannot verify service routing because Pod or DNS is not operational."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE) - YOU ARE CKA READY!"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE) - Keep troubleshooting."
    exit 1
fi