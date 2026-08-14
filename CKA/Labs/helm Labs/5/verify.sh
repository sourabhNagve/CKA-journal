### verify.sh
#!/bin/bash

STATUS="PASS"
echo "Running Verification..."

# 1. Check if Helm release was upgraded (Revision > 1)
HELM_REV=$(helm history dash-frontend -n monitoring -o json 2>/dev/null | jq 'length')
if [ -z "$HELM_REV" ] || [ "$HELM_REV" -le 1 ]; then
    echo "FAIL: Helm release revision is $HELM_REV. You must successfully upgrade the release."
    STATUS="FAIL"
fi

# 2. Check if the ConfigMap was adopted correctly
CM_MANAGED=$(kubectl get configmap dash-frontend-config -n monitoring -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}' 2>/dev/null)
if [ "$CM_MANAGED" != "Helm" ]; then
    echo "FAIL: ConfigMap 'dash-frontend-config' was not adopted properly or was recreated."
    STATUS="FAIL"
fi

# 3. Check if the dependency was deployed (redis pod exists and is running)
REDIS_PHASE=$(kubectl get pod dash-frontend-redis -n monitoring -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$REDIS_PHASE" != "Running" ]; then
    echo "FAIL: Dependency Pod 'dash-frontend-redis' is not Running. Current state: $REDIS_PHASE"
    STATUS="FAIL"
fi

# 4. Check if the frontend deployment has the correct string env value
ENV_TYPE=$(kubectl get deployment dash-frontend -n monitoring -o json | jq -r '.spec.template.spec.containers[0].env[] | select(.name=="BACKEND_PORT") | .value' 2>/dev/null)
if [ "$ENV_TYPE" != "8080" ]; then
    echo "FAIL: Deployment env var BACKEND_PORT does not have the valid string value '8080'."
    STATUS="FAIL"
fi

# 5. Check if frontend pod is running
FRONTEND_PHASE=$(kubectl get pod -l app=dash-frontend -n monitoring -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$FRONTEND_PHASE" != "Running" ]; then
    echo "FAIL: Pod 'dash-frontend' is not Running."
    STATUS="FAIL"
fi

if [ "$STATUS" == "PASS" ]; then
    echo "PASS: Dependencies downloaded, ConfigMap adopted, templates fixed, and upgrade succeeded!"
else
    echo "Validation failed. Please review the errors above."
fi
exit 0