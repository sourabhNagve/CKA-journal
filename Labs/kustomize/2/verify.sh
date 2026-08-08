# verify.sh
#!/bin/bash

PASS=0
FAIL=0

echo "Verifying Kustomize Lab Results..."

# Check 1: Verify deployment exists in the correct namespace with the correct prefix
if kubectl get deployment staging-frontend -n ecommerce-staging &> /dev/null; then
    echo "[PASS] Deployment 'staging-frontend' exists in namespace 'ecommerce-staging'"
    PASS=$((PASS+1))
else
    echo "[FAIL] Deployment 'staging-frontend' NOT found in namespace 'ecommerce-staging'"
    FAIL=$((FAIL+1))
fi

# Check 2: Verify service exists with correct prefix
if kubectl get svc staging-frontend-svc -n ecommerce-staging &> /dev/null; then
    echo "[PASS] Service 'staging-frontend-svc' exists in namespace 'ecommerce-staging'"
    PASS=$((PASS+1))
else
    echo "[FAIL] Service 'staging-frontend-svc' NOT found in namespace 'ecommerce-staging'"
    FAIL=$((FAIL+1))
fi

# Check 3: Verify Replicas = 3
REPLICAS=$(kubectl get deployment staging-frontend -n ecommerce-staging -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
if [ "$REPLICAS" == "3" ]; then
    echo "[PASS] Deployment has 3 replicas"
    PASS=$((PASS+1))
else
    echo "[FAIL] Expected 3 replicas, found $REPLICAS"
    FAIL=$((FAIL+1))
fi

# Check 4: Verify Image
IMAGE=$(kubectl get deployment staging-frontend -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
if [ "$IMAGE" == "nginx:1.25.3-alpine" ]; then
    echo "[PASS] Image is nginx:1.25.3-alpine"
    PASS=$((PASS+1))
else
    echo "[FAIL] Expected image nginx:1.25.3-alpine, found '$IMAGE'"
    FAIL=$((FAIL+1))
fi

# Check 5: Verify Environment Variable
ENV_VAL=$(kubectl get deployment staging-frontend -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="APP_ENV")].value}' 2>/dev/null || echo "")
if [ "$ENV_VAL" == "staging" ]; then
    echo "[PASS] Environment variable APP_ENV=staging is present"
    PASS=$((PASS+1))
else
    echo "[FAIL] Environment variable APP_ENV=staging NOT found or incorrect"
    FAIL=$((FAIL+1))
fi

# Check 6: Ensure Base directory was NOT modified
BASE_MD5=$(cat /root/cka-lab/kustomize-app/base/deployment.yaml | md5sum | awk '{print $1}')
EXPECTED_MD5=$(cat << 'EOF' | md5sum | awk '{print $1}'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.24.0
        ports:
        - containerPort: 80
EOF
)

if [ "$BASE_MD5" == "$EXPECTED_MD5" ]; then
    echo "[PASS] Base deployment was not modified"
    PASS=$((PASS+1))
else
    echo "[FAIL] Base deployment was illegally modified"
    FAIL=$((FAIL+1))
fi

echo "--------------------------------------"
if [ "$FAIL" -eq 0 ] && [ "$PASS" -eq 6 ]; then
    echo "OVERALL RESULT: PASS"
    exit 0
else
    echo "OVERALL RESULT: FAIL ($FAIL errors)"
    exit 1
fi