### verify.sh
#!/bin/bash

STATUS="PASS"
echo "Running Verification..."

# 1. Check if Helm release exists
REVISION=$(helm ls -n logging -q | grep log-processor)
if [ -z "$REVISION" ]; then
    echo "FAIL: Helm release 'log-processor' not found in namespace 'logging'."
    STATUS="FAIL"
fi

# 2. Check if Pod is running (meaning the mount was fixed)
POD_PHASE=$(kubectl get pod log-processor-0 -n logging -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$POD_PHASE" != "Running" ]; then
    echo "FAIL: Pod 'log-processor-0' is not Running. Current state: $POD_PHASE"
    STATUS="FAIL"
fi

# 3. Verify the StatefulSet mount path
MOUNT_PATH=$(kubectl get sts log-processor -n logging -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}' 2>/dev/null)
if [ "$MOUNT_PATH" != "/etc/config" ]; then
    echo "FAIL: StatefulSet volume mount path is '$MOUNT_PATH', expected '/etc/config'."
    STATUS="FAIL"
fi

# 4. Verify the StatefulSet selector remained intact (immutable rule respected)
SELECTOR=$(kubectl get sts log-processor -n logging -o jsonpath='{.spec.selector.matchLabels.app}' 2>/dev/null)
if [ "$SELECTOR" != "log-processor" ]; then
    echo "FAIL: StatefulSet selector is '$SELECTOR', expected 'log-processor'."
    STATUS="FAIL"
fi

# 5. Check if the fix was applied via Helm (Revision > 1)
HELM_REV=$(helm history log-processor -n logging -o json 2>/dev/null | jq 'length')
if [ "$HELM_REV" -le 1 ]; then
    echo "FAIL: Helm release revision is $HELM_REV. You must use 'helm upgrade' to apply the fix."
    STATUS="FAIL"
fi

if [ "$STATUS" == "PASS" ]; then
    echo "PASS: Helm upgrade succeeded, immutable constraint respected, and application is running!"
else
    echo "Validation failed. Please review the errors above."
fi

exit 0