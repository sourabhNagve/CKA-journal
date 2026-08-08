### verify.sh
#!/bin/bash

STATUS="PASS"
echo "Running Verification..."

# 1. Check if Helm release was upgraded (Revision > 1)
HELM_REV=$(helm history data-pipeline -n etl-prod -o json 2>/dev/null | jq 'length')
if [ "$HELM_REV" -le 1 ]; then
    echo "FAIL: Helm release revision is $HELM_REV. You must successfully upgrade the release."
    STATUS="FAIL"
fi

# 2. Check if Secret was adopted correctly (NOT recreated)
SECRET_MANAGED=$(kubectl get secret api-token -n etl-prod -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}' 2>/dev/null)
SECRET_REL_NAME=$(kubectl get secret api-token -n etl-prod -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}' 2>/dev/null)

if [ "$SECRET_MANAGED" != "Helm" ] || [ "$SECRET_REL_NAME" != "data-pipeline" ]; then
    echo "FAIL: Secret 'api-token' is missing required Helm adoption annotations/labels."
    STATUS="FAIL"
fi

# 3. Verify the NetworkPolicy chart fix
NP_SELECTOR=$(kubectl get networkpolicy data-pipeline-allow-redis -n etl-prod -o jsonpath='{.spec.podSelector.matchLabels.app}' 2>/dev/null)
if [ "$NP_SELECTOR" != "data-pipeline" ]; then
    echo "FAIL: NetworkPolicy podSelector matchLabels.app is '$NP_SELECTOR', expected 'data-pipeline'."
    STATUS="FAIL"
fi

# 4. Check if Pod is running (Meaning init container passed network check)
POD_PHASE=$(kubectl get pod -l app=data-pipeline -n etl-prod -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_PHASE" != "Running" ]; then
    echo "FAIL: Pod 'data-pipeline' is not Running. Current state: $POD_PHASE"
    STATUS="FAIL"
fi

if [ "$STATUS" == "PASS" ]; then
    echo "PASS: Helm resource adopted, NetworkPolicy fixed, and upgrade succeeded!"
else
    echo "Validation failed. Please review the errors above."
fi

exit 0