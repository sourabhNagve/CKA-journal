### verify.sh
#!/bin/bash

# Initialize status
STATUS="PASS"

echo "Running Verification..."

# 1. Check if Helm release exists and was upgraded
REVISION=$(helm ls -n payments -q | grep payment-gateway)
if [ -z "$REVISION" ]; then
    echo "FAIL: Helm release 'payment-gateway' not found in namespace 'payments'."
    STATUS="FAIL"
fi

# 2. Check if the values were correctly applied VIA Helm (not just kubectl edit)
HELM_VALUES=$(helm get values payment-gateway -n payments -all)

if ! echo "$HELM_VALUES" | grep -q "secretAccess: true"; then
    echo "FAIL: Helm values do not have rbac.secretAccess set to true."
    STATUS="FAIL"
fi

if ! echo "$HELM_VALUES" | grep -q "security-tier: restricted"; then
    echo "FAIL: Helm values do not have labels.security-tier set to restricted."
    STATUS="FAIL"
fi

if ! echo "$HELM_VALUES" | grep -q "tag: 1.25.3"; then
    echo "FAIL: Helm values do not have image.tag set to 1.25.3."
    STATUS="FAIL"
fi

# 3. Check actual cluster state to ensure pods are running
POD_STATUS=$(kubectl get pods -n payments -l app=payment-gateway -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$POD_STATUS" != "Running" ]; then
    echo "FAIL: Pod is not in Running state. Current state: $POD_STATUS"
    STATUS="FAIL"
fi

# 4. Verify RBAC directly
ROLE_PERM=$(kubectl get role payment-gateway-role -n payments -o jsonpath='{.rules[0].resources[0]}' 2>/dev/null)
if [ "$ROLE_PERM" != "secrets" ]; then
    echo "FAIL: Role 'payment-gateway-role' does not have permissions for 'secrets'."
    STATUS="FAIL"
fi

# 5. Verify Labels directly
POD_LABEL=$(kubectl get deployment payment-gateway -n payments -o jsonpath='{.spec.template.metadata.labels.security-tier}' 2>/dev/null)
if [ "$POD_LABEL" != "restricted" ]; then
    echo "FAIL: Pod template is missing the 'security-tier: restricted' label required for NetworkPolicy."
    STATUS="FAIL"
fi

if [ "$STATUS" == "PASS" ]; then
    echo "PASS: All checks succeeded! Helm release is healthy and compliant."
else
    echo "Validation failed. Please review the errors above."
fi

exit 0