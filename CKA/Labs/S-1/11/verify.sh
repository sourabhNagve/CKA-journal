#!/bin/bash

SCORE=0
MAX_SCORE=5

echo "Running automated verification..."

# 1. Check if Endpoints object exists and points to the correct IP
ENDPOINT_IP=$(kubectl get endpoints external-cache -n cart-system -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
if [ "$ENDPOINT_IP" == "10.20.30.40" ]; then
    echo "[PASS] Manual Endpoints object created and mapped to 10.20.30.40."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] 'external-cache' Endpoints missing or mapped to wrong IP (Found: $ENDPOINT_IP)."
fi

# 2. Check Deployment Strategy
STRATEGY_TYPE=$(kubectl get deploy cart-backend -n cart-system -o jsonpath='{.spec.strategy.type}' 2>/dev/null)
MAX_UNAVAILABLE=$(kubectl get deploy cart-backend -n cart-system -o jsonpath='{.spec.strategy.rollingUpdate.maxUnavailable}' 2>/dev/null)

if [ "$STRATEGY_TYPE" == "RollingUpdate" ] && { [ "$MAX_UNAVAILABLE" == "25%" ] || [ "$MAX_UNAVAILABLE" == "1" ]; }; then
    echo "[PASS] Deployment rollout strategy configured to prevent massive downtime (maxUnavailable: 25% or 1)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Deployment strategy is incorrect. maxUnavailable must ensure 75% availability."
fi

# 3. Check Secret Key Reference
SECRET_KEY=$(kubectl get deploy cart-backend -n cart-system -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="CACHE_PASS")].valueFrom.secretKeyRef.key}' 2>/dev/null)
if [ "$SECRET_KEY" == "redis-pass" ]; then
    echo "[PASS] Secret key reference corrected to 'redis-pass'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Secret key reference is still incorrect (Found: $SECRET_KEY)."
fi

# 4. Check Readiness Probe Port
PROBE_PORT=$(kubectl get deploy cart-backend -n cart-system -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}' 2>/dev/null)
if [ "$PROBE_PORT" == "80" ]; then
    echo "[PASS] Readiness probe port corrected to 80."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Readiness probe port is incorrect (Found: $PROBE_PORT)."
fi

# 5. Check if Pods are Ready
READY_REPLICAS=$(kubectl get deploy cart-backend -n cart-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$READY_REPLICAS" == "4" ]; then
    echo "[PASS] All 4 replicas are Running and Ready!"
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Pods are not fully Ready. (Currently Ready: ${READY_REPLICAS:-0}/4)."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi