#!/bin/bash
set -eo pipefail

NS="redis-cluster"
DEPLOY="cache-node"

echo "Verifying Scenario 4 constraints..."

# 1. Check Ephemeral Storage Limits/Requests
REQ_EPH=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.containers[0].resources.requests['ephemeral-storage']}")
LIM_EPH=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.containers[0].resources.limits['ephemeral-storage']}")

if [ "$REQ_EPH" == "500Mi" ] && [ "$LIM_EPH" == "1Gi" ]; then
    echo "[PASS] Ephemeral storage strictly bounded (Req: 500Mi, Lim: 1Gi)."
else
    echo "[FAIL] Ephemeral storage bounds incorrect. (Req: $REQ_EPH, Lim: $LIM_EPH)."
fi

# 2. Check PreStop Lifecycle Hook
PRESTOP_CMD=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[*]}")

if [[ "$PRESTOP_CMD" == *"/bin/sh -c sleep 15"* ]]; then
    echo "[PASS] preStop lifecycle hook configured correctly for graceful termination."
else
    echo "[FAIL] preStop lifecycle hook missing or incorrect. (Found: $PRESTOP_CMD)"
fi

# 3. Check TopologySpreadConstraints
SKEW=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.topologySpreadConstraints[0].maxSkew}")
TOP_KEY=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.topologySpreadConstraints[0].topologyKey}")
ACTION=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}")
MATCH_LABEL=$(kubectl get deploy $DEPLOY -n $NS -o jsonpath="{.spec.template.spec.topologySpreadConstraints[0].labelSelector.matchLabels.app}")

if [ "$SKEW" == "1" ] && [ "$TOP_KEY" == "topology.kubernetes.io/zone" ] && [ "$ACTION" == "DoNotSchedule" ] && [ "$MATCH_LABEL" == "cache-node" ]; then
    echo "[PASS] TopologySpreadConstraint configured for strict zonal high-availability."
else
    echo "[FAIL] TopologySpreadConstraint incorrect. (Skew: $SKEW, Key: $TOP_KEY, Action: $ACTION)"
fi