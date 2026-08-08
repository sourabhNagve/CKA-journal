#!/bin/bash
set -eo pipefail

NS="identity"
DEPLOY="auth-service"
SECRET="jwt-keys"

echo "Verifying Scenario 2 constraints..."

# 1. Check Immutable Secret
IMMUTABLE=$(kubectl get secret $SECRET -n $NS -o jsonpath='{.immutable}')
if [ "$IMMUTABLE" == "true" ]; then
    echo "[PASS] Secret $SECRET is immutable."
else
    echo "[FAIL] Secret $SECRET is not immutable."
fi

# 2. Check Volume Mounts
MOUNT_PATH=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="certs-vol")].mountPath}')
SECRET_REF=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.volumes[?(@.name=="certs-vol")].secret.secretName}')
if [ "$MOUNT_PATH" == "/etc/certs" ] && [ "$SECRET_REF" == "$SECRET" ]; then
    echo "[PASS] Secret properly mounted at /etc/certs."
else
    echo "[FAIL] Secret mount incorrect (Path: $MOUNT_PATH, Ref: $SECRET_REF)."
fi

# 3. Check Aggressive Liveness Probe & Fixed Readiness Port
LIVENESS_TIMEOUT=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.timeoutSeconds}')
LIVENESS_THRESH=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.failureThreshold}')
READINESS_PORT=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}')

if [ "$LIVENESS_TIMEOUT" == "1" ] && [ "$LIVENESS_THRESH" == "2" ] && [ "$READINESS_PORT" == "8080" ]; then
    echo "[PASS] Probes correctly configured for aggressive self-healing."
else
    echo "[FAIL] Probes incorrect. (Timeout: $LIVENESS_TIMEOUT, Thresh: $LIVENESS_THRESH, ReadyPort: $READINESS_PORT)"
fi

# 4. Check Pod Anti-Affinity
ANTI_AFFINITY_TOPOLOGY=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}')
if [ "$ANTI_AFFINITY_TOPOLOGY" == "kubernetes.io/hostname" ]; then
    echo "[PASS] Required PodAntiAffinity configured with hostname topology."
else
    echo "[FAIL] PodAntiAffinity missing or incorrect."
fi