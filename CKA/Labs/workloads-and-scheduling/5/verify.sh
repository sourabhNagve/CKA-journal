#!/bin/bash
set -eo pipefail

NS="messaging"

echo "Verifying Scenario 8 constraints..."

# 1. Check Headless Service
CLUSTER_IP=$(kubectl get svc kafka-svc -n $NS -o jsonpath='{.spec.clusterIP}')
if [ "$CLUSTER_IP" == "None" ]; then
    echo "[PASS] Service kafka-svc is correctly configured as Headless."
else
    echo "[FAIL] Service kafka-svc is not Headless (clusterIP is $CLUSTER_IP)."
fi

# 2. Check PV Reclaim Policy
RECLAIM_0=$(kubectl get pv pv-kafka-0 -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')
RECLAIM_1=$(kubectl get pv pv-kafka-1 -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')

if [ "$RECLAIM_0" == "Retain" ] && [ "$RECLAIM_1" == "Retain" ]; then
    echo "[PASS] PersistentVolume reclaim policies updated to Retain to prevent data loss."
else
    echo "[FAIL] PersistentVolume reclaim policies are incorrect (PV0: $RECLAIM_0, PV1: $RECLAIM_1)."
fi

# 3. Check PVC Capacity
PVC_0_SIZE=$(kubectl get pvc data-kafka-0 -n $NS -o jsonpath='{.spec.resources.requests.storage}')
PVC_1_SIZE=$(kubectl get pvc data-kafka-1 -n $NS -o jsonpath='{.spec.resources.requests.storage}')

if [ "$PVC_0_SIZE" == "3Gi" ] && [ "$PVC_1_SIZE" == "3Gi" ]; then
    echo "[PASS] PVCs correctly expanded to 3Gi."
else
    echo "[FAIL] PVC expansion failed. (PVC0: $PVC_0_SIZE, PVC1: $PVC_1_SIZE)."
fi