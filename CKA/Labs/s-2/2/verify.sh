#!/bin/bash

SCORE=0
MAX_SCORE=5

echo "Running automated verification..."

# 1. Check if the defunct Webhook was deleted
if kubectl get validatingwebhookconfiguration shield-webhook.acme.com >/dev/null 2>&1; then
    echo "[FAIL] shield-webhook.acme.com still exists. It is blocking pod creation."
else
    echo "[PASS] Defunct ValidatingWebhookConfiguration removed."
    SCORE=$((SCORE+1))
fi

# 2. Check if ServiceAccount was created
if kubectl get sa gateway-sa -n app-prod >/dev/null 2>&1; then
    echo "[PASS] ServiceAccount 'gateway-sa' exists."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] ServiceAccount 'gateway-sa' is missing."
fi

# 3. Check Secret Name Correction
SECRET_NAME=$(kubectl get deploy payment-gateway -n app-prod -o jsonpath='{.spec.template.spec.volumes[0].secret.secretName}' 2>/dev/null)
if [ "$SECRET_NAME" == "gateway-certs" ]; then
    echo "[PASS] Deployment volume corrected to reference 'gateway-certs'."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Deployment volume references incorrect secret name (Currently: $SECRET_NAME)."
fi

# 4. Check Secret Key Projection (items mapping)
ITEMS_KEY=$(kubectl get deploy payment-gateway -n app-prod -o jsonpath='{.spec.template.spec.volumes[0].secret.items[0].key}' 2>/dev/null)
ITEMS_PATH=$(kubectl get deploy payment-gateway -n app-prod -o jsonpath='{.spec.template.spec.volumes[0].secret.items[0].path}' 2>/dev/null)

if [ "$ITEMS_KEY" == "cert.pem" ] && [ "$ITEMS_PATH" == "tls.crt" ]; then
    echo "[PASS] Secret keys correctly mapped via 'items' (cert.pem -> tls.crt)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Secret 'items' mapping is missing or incorrect. Pod cannot find 'tls.crt'."
fi

# 5. Check End-to-End Status
POD_NAME=$(kubectl get pods -n app-prod -l app=payment -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    sleep 3
    LOGS=$(kubectl logs "$POD_NAME" -n app-prod 2>/dev/null | tail -n 2)
    
    if echo "$LOGS" | grep -q "Cert found, starting..."; then
        echo "[PASS] Pod is Running and successfully verified the mounted certificate."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] Pod is failing. Recent logs: $LOGS"
    fi
else
    echo "[FAIL] payment-gateway pod not found."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi