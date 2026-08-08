### verify.sh
#!/bin/bash

STATUS="PASS"
echo "Running Verification..."

# 1. Check if Deployment exists in the correct namespace
if ! kubectl get deployment billing-app -n finance >/dev/null 2>&1; then
    echo "FAIL: Deployment 'billing-app' not found in namespace 'finance'."
    STATUS="FAIL"
fi

# 2. Check Replicas (Validates JSONPatch fix)
REPLICAS=$(kubectl get deployment billing-app -n finance -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
if [ "$REPLICAS" -ne 3 ]; then
    echo "FAIL: Deployment 'billing-app' has $REPLICAS replicas, expected 3. The JSONPatch was not applied correctly."
    STATUS="FAIL"
fi

# 3. Check Image Override (Validates 'images:' in kustomization.yaml)
IMAGE=$(kubectl get deployment billing-app -n finance -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "$IMAGE" != "nginx:1.26.0" ]; then
    echo "FAIL: Deployment is using image '$IMAGE', expected 'nginx:1.26.0'."
    STATUS="FAIL"
fi

# 4. Check ConfigMap generation and attachment (Validates configMapGenerator)
CM_REF=$(kubectl get deployment billing-app -n finance -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)
if [[ ! "$CM_REF" == billing-config-* ]]; then
    echo "FAIL: Deployment is not referencing a Kustomize-hashed ConfigMap. Current reference: '$CM_REF'."
    STATUS="FAIL"
fi

# 5. Check if the generated ConfigMap actually exists in the cluster
if ! kubectl get configmap "$CM_REF" -n finance >/dev/null 2>&1; then
    echo "FAIL: The generated ConfigMap '$CM_REF' does not exist in the cluster."
    STATUS="FAIL"
fi

# 6. Check if Pods are running
POD_READY=$(kubectl get deploy billing-app -n finance -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [ "$POD_READY" -ne 3 ]; then
    echo "FAIL: Expected 3 ready pods, but found $POD_READY."
    STATUS="FAIL"
fi

# 7. Check Constraints (Ensure base was not modified)
BASE_REPLICAS=$(grep -c "replicas: 1" /opt/kustomize/billing/base/deployment.yaml || true)
BASE_IMAGE=$(grep -c "image: nginx:1.19.0" /opt/kustomize/billing/base/deployment.yaml || true)

if [ "$BASE_REPLICAS" -eq 0 ] || [ "$BASE_IMAGE" -eq 0 ]; then
    echo "FAIL: You modified the base deployment at /opt/kustomize/billing/base/deployment.yaml! This violates the constraints."
    STATUS="FAIL"
fi

if [ "$STATUS" == "PASS" ]; then
    echo "PASS: All checks succeeded! Kustomize overlay is correctly configured and applied."
else
    echo "Validation failed. Please review the errors above."
fi

exit 0