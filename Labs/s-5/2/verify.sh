# the solution is using the affinity , you can do it with nodeSelector as well and for the second question sidecar is native, you can also use the colocated containers.
#!/bin/bash

SCORE=0
MAX_SCORE=3

echo "Running automated verification for Round 2..."

# ==========================================
# Question 1 Verification
# ==========================================
TOLERATION=$(kubectl get deploy ml-processor -n processing -o jsonpath='{.spec.template.spec.tolerations[?(@.key=="maintenance")].operator}' 2>/dev/null)
AFFINITY=$(kubectl get deploy ml-processor -n processing -o jsonpath='{.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key}' 2>/dev/null)
READY_REPLICAS=$(kubectl get deploy ml-processor -n processing -o jsonpath='{.status.readyReplicas}' 2>/dev/null)

if [[ "$TOLERATION" == "Equal" || "$TOLERATION" == "Exists" ]] && [[ "$AFFINITY" == "hardware" ]] && [[ "$READY_REPLICAS" == "2" ]]; then
    echo "[PASS] Q1: Deployment respects NodeAffinity and tolerates the maintenance taint."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Q1: Deployment missing tolerations, nodeAffinity, or pods are not running."
fi

# ==========================================
# Question 2 Verification
# ==========================================
SIDECAR_EXISTS=$(kubectl get pod legacy-app -o jsonpath='{.spec.containers[?(@.name=="log-reader")].name}' 2>/dev/null)
COMMAND=$(kubectl get pod legacy-app -o jsonpath='{.spec.containers[?(@.name=="log-reader")].command[2]}' 2>/dev/null)

if [[ "$SIDECAR_EXISTS" == "log-reader" ]] && [[ "$COMMAND" == *"tail -f"* ]]; then
    echo "[PASS] Q2: Sidecar container 'log-reader' successfully injected and streaming logs."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Q2: Sidecar container missing or misconfigured."
fi

# ==========================================
# Question 3 Verification
# ==========================================
HOST=$(kubectl get ingress media-ingress -n media-ns -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)
VIDEO_PORT=$(kubectl get ingress media-ingress -n media-ns -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/video")].backend.service.port.number}' 2>/dev/null)
AUDIO_PORT=$(kubectl get ingress media-ingress -n media-ns -o jsonpath='{.spec.rules[0].http.paths[?(@.path=="/audio")].backend.service.port.number}' 2>/dev/null)

if [[ "$HOST" == "media.company.internal" ]] && [[ "$VIDEO_PORT" == "8080" ]] && [[ "$AUDIO_PORT" == "9090" ]]; then
    echo "[PASS] Q3: Ingress routing configured perfectly."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] Q3: Ingress resource missing or paths/ports misconfigured."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE) - EXCEPTIONAL!"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE) - Review the solutions."
    exit 1
fi