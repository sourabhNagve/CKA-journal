#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check Node Bootstrapping (kubeadm join command)
if [ -f "/opt/join-command.txt" ] && grep -q "kubeadm join" "/opt/join-command.txt"; then
    echo "[PASS] kubeadm join command successfully generated and saved."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] /opt/join-command.txt is missing or does not contain a valid join command."
fi

# 2. Check Helm Deployment
if helm status frontend-web -n web-fleet >/dev/null 2>&1; then
    echo "[PASS] Helm release 'frontend-web' is successfully installed."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Helm release 'frontend-web' not found in web-fleet namespace."
fi

# 3. Check Dynamic Volume Provisioning
PVC_SC=$(kubectl get pvc dynamic-pvc -n web-fleet -o jsonpath='{.spec.storageClassName}' 2>/dev/null)
PVC_REQ=$(kubectl get pvc dynamic-pvc -n web-fleet -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null)

if [[ "$PVC_SC" == "fast-storage" ]] && [[ "$PVC_REQ" == "1Gi" ]]; then
    echo "[PASS] Dynamic PVC created and mapped to 'fast-storage' StorageClass."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] PVC 'dynamic-pvc' is missing, wrong capacity, or not pointing to the correct StorageClass."
fi

# 4. Check Custom Resource
CR_IMAGE=$(kubectl get crontab nightly-backup -n web-fleet -o jsonpath='{.spec.image}' 2>/dev/null)
if [[ "$CR_IMAGE" == "backup-image:v1" ]]; then
    echo "[PASS] Custom Resource 'nightly-backup' created successfully from the CRD."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Custom Resource missing or incorrectly configured."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE) - SYLLABUS COMPLETE!"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi