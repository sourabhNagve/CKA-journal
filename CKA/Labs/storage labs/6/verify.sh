#!/bin/bash
set -eo pipefail

NS="transactions"
DEPLOY="order-processor"
HPA="order-hpa"

echo "Verifying Scenario 6 constraints..."

# 1. Check ConfigMap Existence & Content
CM_CONTENT=$(kubectl get cm db-init-script -n $NS -o jsonpath="{.data['migrate\.sh']}" || echo "missing")

if [[ "$CM_CONTENT" == *"echo \"Migrating...\""* ]]; then
    echo "[PASS] ConfigMap db-init-script created with migrate.sh content."
else
    echo "[FAIL] ConfigMap missing or migrate.sh content incorrect. (Found: $CM_CONTENT)"
fi

# 2. Check InitContainer Mounts
INIT_MOUNT=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}")
INIT_VOL_CM=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.volumes[?(@.name=='script-vol')].configMap.name}")

if [ "$INIT_MOUNT" == "/scripts" ] && [ "$INIT_VOL_CM" == "db-init-script" ]; then
    echo "[PASS] InitContainer volume correctly mounted to /scripts using the ConfigMap."
else
    echo "[FAIL] InitContainer mount incorrect. (Path: $INIT_MOUNT, Vol: $INIT_VOL_CM)."
fi

# 3. Check HPA ScaleDown Behavior
BEHAVIOR_TYPE=$(kubectl get hpa $HPA -n $NS -o jsonpath="{.spec.behavior.scaleDown.policies[0].type}")
BEHAVIOR_VAL=$(kubectl get hpa $HPA -n $NS -o jsonpath="{.spec.behavior.scaleDown.policies[0].value}")
BEHAVIOR_PERIOD=$(kubectl get hpa $HPA -n $NS -o jsonpath="{.spec.behavior.scaleDown.policies[0].periodSeconds}")

if [ "$BEHAVIOR_TYPE" == "Pods" ] && [ "$BEHAVIOR_VAL" == "1" ] && [ "$BEHAVIOR_PERIOD" == "60" ]; then
    echo "[PASS] HPA scaleDown behavior correctly throttled to 1 Pod per 60 seconds."
else
    echo "[FAIL] HPA behavior incorrect. (Type: $BEHAVIOR_TYPE, Value: $BEHAVIOR_VAL, Period: $BEHAVIOR_PERIOD)."
fi