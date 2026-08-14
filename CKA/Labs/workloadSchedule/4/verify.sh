#!/bin/bash
set -eo pipefail

NS="security"

echo "Verifying Scenario 9 constraints..."

# 1. Check NetworkPolicy Egress Rules
POLICY_TYPES=$(kubectl get netpol vault-egress-strict -n $NS -o jsonpath='{.spec.policyTypes[*]}')
TARGET_CIDR=$(kubectl get netpol vault-egress-strict -n $NS -o jsonpath='{.spec.egress[0].to[0].ipBlock.cidr}')
TARGET_PORT=$(kubectl get netpol vault-egress-strict -n $NS -o jsonpath='{.spec.egress[0].ports[0].port}')
TARGET_APP=$(kubectl get netpol vault-egress-strict -n $NS -o jsonpath='{.spec.podSelector.matchLabels.app}')

if [[ "$POLICY_TYPES" == *"Egress"* ]] && [ "$TARGET_CIDR" == "169.254.169.254/32" ] && [ "$TARGET_PORT" == "80" ] && [ "$TARGET_APP" == "vault-agent" ]; then
    echo "[PASS] NetworkPolicy vault-egress-strict correctly configured for strict Egress lockdown."
else
    echo "[FAIL] NetworkPolicy Egress rules incorrect. (CIDR: $TARGET_CIDR, Port: $TARGET_PORT, Types: $POLICY_TYPES)."
fi

# 2. Check Revocation of Cluster-Wide Privilege
if kubectl get clusterrolebinding vault-global-secret-reader > /dev/null 2>&1; then
    echo "[FAIL] The highly permissive ClusterRoleBinding vault-global-secret-reader still exists!"
else
    echo "[PASS] Dangerous ClusterRoleBinding successfully deleted."
fi

# 3. Check Local Least-Privilege Binding
ROLEBINDING_SA=$(kubectl get rolebinding vault-local-reader -n $NS -o jsonpath='{.subjects[?(@.name=="vault-agent")].name}' || echo "")
ROLEBINDING_REF=$(kubectl get rolebinding vault-local-reader -n $NS -o jsonpath='{.roleRef.name}' || echo "")

if [ "$ROLEBINDING_SA" == "vault-agent" ] && [ "$ROLEBINDING_REF" == "secret-reader" ]; then
    echo "[PASS] RoleBinding vault-local-reader successfully downgrades secret access to the namespace level."
else
    echo "[FAIL] RoleBinding vault-local-reader missing or incorrectly mapped."
fi