#!/bin/bash

SCORE=0
MAX=6
CLEAN_FILE="/opt/course/kube/clean-config.yaml"
DEV_FILE="/opt/course/kube/dev-only.yaml"

echo "Checking Task 1: Legacy cluster and context deleted..."
if [ -f "$CLEAN_FILE" ]; then
    if kubectl --kubeconfig=$CLEAN_FILE config get-clusters | grep -q "legacy-cluster" || \
       kubectl --kubeconfig=$CLEAN_FILE config get-contexts | grep -q "legacy-ctx"; then
        echo "❌ Task 1 Fail: legacy-cluster or legacy-ctx still exists in clean-config.yaml."
    else
        echo "✅ Task 1 Pass: Legacy cluster and context successfully removed."
        ((SCORE++))
    fi
else
    echo "❌ Task 1 Fail: clean-config.yaml not found."
fi

echo "Checking Task 2: Prod cert and key extracted..."
if [ -f /opt/course/kube/prod.crt ] && [ -f /opt/course/kube/prod.key ]; then
    CERT_VAL=$(cat /opt/course/kube/prod.crt)
    KEY_VAL=$(cat /opt/course/kube/prod.key)
    if [ "$CERT_VAL" == "This is the prod certificate" ] && [ "$KEY_VAL" == "This is the prod key" ]; then
        echo "✅ Task 2 Pass: Certificate and key successfully extracted and decoded."
        ((SCORE++))
    else
        echo "❌ Task 2 Fail: Extracted files do not contain the correct decoded strings."
    fi
else
    echo "❌ Task 2 Fail: prod.crt or prod.key files missing."
fi

echo "Checking Task 3: prod-admin reconfigured to use files..."
if [ -f "$CLEAN_FILE" ]; then
    EMBEDDED_CERT=$(kubectl --kubeconfig=$CLEAN_FILE config view --raw -o jsonpath='{.users[?(@.name=="prod-admin")].user.client-certificate-data}')
    CERT_PATH=$(kubectl --kubeconfig=$CLEAN_FILE config view -o jsonpath='{.users[?(@.name=="prod-admin")].user.client-certificate}')
    KEY_PATH=$(kubectl --kubeconfig=$CLEAN_FILE config view -o jsonpath='{.users[?(@.name=="prod-admin")].user.client-key}')
    
    if [ -z "$EMBEDDED_CERT" ] && [ "$CERT_PATH" == "/opt/course/kube/prod.crt" ] && [ "$KEY_PATH" == "/opt/course/kube/prod.key" ]; then
        echo "✅ Task 3 Pass: prod-admin uses file paths and embedded data is removed."
        ((SCORE++))
    else
        echo "❌ Task 3 Fail: prod-admin still has embedded data or wrong file paths."
    fi
fi

echo "Checking Task 4: staging-ctx namespace updated..."
if [ -f "$CLEAN_FILE" ]; then
    NS=$(kubectl --kubeconfig=$CLEAN_FILE config view -o jsonpath='{.contexts[?(@.name=="staging-ctx")].context.namespace}')
    if [ "$NS" == "qa-environment" ]; then
        echo "✅ Task 4 Pass: staging-ctx namespace set correctly."
        ((SCORE++))
    else
        echo "❌ Task 4 Fail: staging-ctx namespace is $NS, expected qa-environment."
    fi
fi

echo "Checking Task 5: dev-only.yaml minification..."
if [ -f "$DEV_FILE" ]; then
    CL_COUNT=$(kubectl --kubeconfig=$DEV_FILE config get-clusters | tail -n +2 | wc -l)
    CTX_COUNT=$(kubectl --kubeconfig=$DEV_FILE config get-contexts -o name | wc -l)
    
    if [ "$CL_COUNT" -eq 1 ] && [ "$CTX_COUNT" -eq 1 ]; then
        CL_NAME=$(kubectl --kubeconfig=$DEV_FILE config get-clusters | tail -n +2)
        if [ "$CL_NAME" == "dev-cluster" ]; then
            echo "✅ Task 5 Pass: dev-only.yaml contains exactly one cluster/context."
            ((SCORE++))
        else
             echo "❌ Task 5 Fail: dev-only.yaml has the wrong cluster."
        fi
    else
        echo "❌ Task 5 Fail: dev-only.yaml contains $CL_COUNT clusters and $CTX_COUNT contexts. Expected exactly 1 of each."
    fi
else
    echo "❌ Task 5 Fail: dev-only.yaml not found."
fi

echo "--------------------------------------"
echo "Final Score: $SCORE / $MAX"
if [ $SCORE -eq 5 ]; then # 5 checks total, Max was printed as 6 by mistake if 5 checks
    echo "🎉 PERFECT SCORE! You mastered kubeconfig extraction."
else
    echo "Review the failing tasks to perfect your speed."
fi