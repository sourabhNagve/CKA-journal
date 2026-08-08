#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check if CSR exists and is Approved
CSR_STATUS=$(kubectl get csr jane-developer -o jsonpath='{.status.conditions[?(@.type=="Approved")].status}' 2>/dev/null)
if [ "$CSR_STATUS" == "True" ]; then
    echo "[PASS] CSR 'jane-developer' exists and is Approved."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] CSR 'jane-developer' is missing or not Approved."
fi

# 2. Check RBAC (Can user 'jane' list pods in dev-team?)
AUTH_CHECK=$(kubectl auth can-i list pods -n dev-team --as=jane 2>/dev/null)
if [ "$AUTH_CHECK" == "yes" ]; then
    echo "[PASS] User 'jane' has the correct RBAC permissions in dev-team namespace."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] User 'jane' cannot list pods in dev-team. Check your Role and RoleBinding."
fi

# 3. Check RBAC Boundary (Ensure 'jane' cannot list pods in kube-system)
AUTH_BOUNDARY=$(kubectl auth can-i list pods -n kube-system --as=jane 2>/dev/null)
if [ "$AUTH_BOUNDARY" == "no" ]; then
    echo "[PASS] User 'jane' is properly restricted from other namespaces (Principle of Least Privilege)."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] User 'jane' has cluster-wide permissions. RBAC is too permissive."
fi

# 4. Check the Custom Kubeconfig File
if [ -f "/opt/jane/jane.kubeconfig" ]; then
    # Try to use her kubeconfig to list pods
    KUBECONFIG_TEST=$(kubectl --kubeconfig=/opt/jane/jane.kubeconfig get pods -n dev-team 2>&1)
    
    if echo "$KUBECONFIG_TEST" | grep -q -E "No resources found|NAME"; then
        echo "[PASS] Kubeconfig file at /opt/jane/jane.kubeconfig successfully authenticates against the cluster."
        SCORE=$((SCORE+1))
    else
        echo "[FAIL] Kubeconfig exists but failed to authenticate. Error:"
        echo "$KUBECONFIG_TEST"
    fi
else
    echo "[FAIL] Kubeconfig file not found at /opt/jane/jane.kubeconfig."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi