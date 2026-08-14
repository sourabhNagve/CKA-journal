#!/bin/bash

SCORE=0
MAX_SCORE=4

echo "Running automated verification..."

# 1. Check CoreDNS Health
COREDNS_READY=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[*].status.containerStatuses[*].ready}' 2>/dev/null)
if [[ "$COREDNS_READY" == *"true"* && "$COREDNS_READY" != *"false"* ]]; then
    echo "[PASS] CoreDNS pods are back online and Ready."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] CoreDNS pods are still crashing or not fully Ready. Check the coredns ConfigMap in kube-system."
fi

# 2. Check Service Endpoints
ENDPOINTS=$(kubectl get endpoints db-service -n db-ns -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)
if [ -n "$ENDPOINTS" ]; then
    echo "[PASS] db-service correctly routes to db-backend pods."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] db-service has no endpoints. The Service selector is likely incorrect."
fi

# 3. Check Auth Service DNS Policy
DNS_POLICY=$(kubectl get deploy auth-service -n auth-ns -o jsonpath='{.spec.template.spec.dnsPolicy}' 2>/dev/null)
if [ "$DNS_POLICY" == "ClusterFirst" ] || [ -z "$DNS_POLICY" ]; then
    echo "[PASS] auth-service dnsPolicy corrected to ClusterFirst."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] auth-service dnsPolicy is still '$DNS_POLICY' (Expected: ClusterFirst). It cannot resolve internal DNS."
fi

# 4. Check End-to-End Auth Service Pod Status
AUTH_POD_PHASE=$(kubectl get pods -n auth-ns -l app=auth -o jsonpath='{.items[0].status.phase}' 2>/dev/null)
if [ "$AUTH_POD_PHASE" == "Running" ]; then
    echo "[PASS] auth-service pod successfully resolved the DB and is Running."
    SCORE=$((SCORE+1))
else
    echo "[FAIL] auth-service pod is not Running (Current: ${AUTH_POD_PHASE:-NotFound})."
fi

echo "=============================="
if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "OVERALL: PASS ($SCORE/$MAX_SCORE)"
    exit 0
else
    echo "OVERALL: FAIL ($SCORE/$MAX_SCORE)"
    exit 1
fi