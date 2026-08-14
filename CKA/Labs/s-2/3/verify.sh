#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check SecurityContext (runAsUser)
RUN_AS_USER=$(kubectl get deploy crypto-service -n secure-enclave -o jsonpath='{.spec.template.spec.securityContext.runAsUser}' 2>/dev/null)
if [ -n "$RUN_AS_USER" ]; then
    echo "[PASS] runAsUser is configured in Pod SecurityContext."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] runAsUser is missing. Pod will fail with CreateContainerConfigError."
fi

# 2. Check Readiness Probe Port
PROBE_PORT=$(kubectl get deploy crypto-service -n secure-enclave -o jsonpath='{.spec.template.spec.containers[?(@.name=="api")].readinessProbe.httpGet.port}' 2>/dev/null)
if [ "$PROBE_PORT" == "80" ]; then
    echo "[PASS] Readiness probe port corrected to 80."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Readiness probe port is incorrect (Currently: $PROBE_PORT). The 'api' container will never become Ready."
fi

# 3. Check Sidecar Volume Mount Path
MOUNT_PATH=$(kubectl get deploy crypto-service -n secure-enclave -o jsonpath='{.spec.template.spec.containers[?(@.name=="key-loader")].volumeMounts[0].mountPath}' 2>/dev/null)
if [ "$MOUNT_PATH" == "/var/keys" ]; then
    echo "[PASS] Secret volume mount path corrected to /var/keys."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Secret volume mount path is incorrect (Currently: $MOUNT_PATH). The 'key-loader' sidecar will CrashLoopBackOff."
fi

# 4. Check Service Selector
SVC_SELECTOR=$(kubectl get svc crypto-svc -n secure-enclave -o jsonpath='{.spec.selector.app}' 2>/dev/null)
if [ "$SVC_SELECTOR" == "crypto-service" ]; then
    echo "[PASS] Service selector corrected to target the deployment pods."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Service selector is incorrect (Currently: $SVC_SELECTOR). It will not route traffic to the pods."
fi

# End-to-End Health Check
POD_NAME=$(kubectl get pods -n secure-enclave -l app=crypto-service -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$POD_NAME" ]; then
    POD_READY=$(kubectl get pod "$POD_NAME" -n secure-enclave -o jsonpath='{.status.containerStatuses[*].ready}')
    if [[ "$POD_READY" == *"true true"* ]] || [[ "$POD_READY" == *"true"* && $(echo "$POD_READY" | wc -w) -eq 2 ]]; then
        echo "--> All containers are Running and Ready!"
    else
        echo "--> Waiting for containers to become Ready. Current pod state: $(kubectl get pod "$POD_NAME" -n secure-enclave -o jsonpath='{.status.phase}')"
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