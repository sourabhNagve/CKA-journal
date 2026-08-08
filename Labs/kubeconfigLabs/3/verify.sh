#!/bin/bash

SCORE=0
MAX=5
MASTER="/opt/course/kube3/master.yaml"

echo "Checking Task 1: Merged master.yaml exists with all resources..."
if [ -f "$MASTER" ]; then
    CL=$(kubectl --kubeconfig=$MASTER config get-clusters | tail -n +2 | wc -l)
    CTX=$(kubectl --kubeconfig=$MASTER config get-contexts -o name | wc -l)
    USR=$(kubectl --kubeconfig=$MASTER config view -o jsonpath='{.users[*].name}' | wc -w)
    
    if [ "$CL" -eq 3 ] && [ "$CTX" -eq 3 ] && [ "$USR" -eq 3 ]; then
        echo "✅ Task 1 Pass: master.yaml contains 3 clusters, 3 contexts, and 3 users."
        ((SCORE++))
    else
        echo "❌ Task 1 Fail: master.yaml resource counts are incorrect (Clusters:$CL, Contexts:$CTX, Users:$USR)."
    fi
else
    echo "❌ Task 1 Fail: master.yaml not found."
fi

echo "Checking Task 2: test-ctx user repaired..."
if [ -f "$MASTER" ]; then
    TEST_USER=$(kubectl --kubeconfig=$MASTER config view -o jsonpath='{.contexts[?(@.name=="test-ctx")].context.user}')
    if [ "$TEST_USER" == "test-user" ]; then
        echo "✅ Task 2 Pass: test-ctx is using test-user."
        ((SCORE++))
    else
        echo "❌ Task 2 Fail: test-ctx is using $TEST_USER instead of test-user."
    fi
fi

echo "Checking Task 3: prod-cluster CA embedded..."
if [ -f "$MASTER" ]; then
    CA_DATA=$(kubectl --kubeconfig=$MASTER config view --raw -o jsonpath='{.clusters[?(@.name=="prod-cluster")].cluster.certificate-authority-data}')
    CA_FILE=$(kubectl --kubeconfig=$MASTER config view -o jsonpath='{.clusters[?(@.name=="prod-cluster")].cluster.certificate-authority}')
    
    if [ -n "$CA_DATA" ] && [ -z "$CA_FILE" ]; then
        DECODED=$(echo "$CA_DATA" | base64 -d)
        if [[ "$DECODED" == *"BEGIN CERTIFICATE"* ]]; then
            echo "✅ Task 3 Pass: prod-cluster CA is properly embedded and base-64 encoded."
            ((SCORE++))
        else
            echo "❌ Task 3 Fail: CA data is embedded but contents are incorrect."
        fi
    else
        echo "❌ Task 3 Fail: CA data is not embedded (missing certificate-authority-data or still pointing to a file path)."
    fi
fi

echo "Checking Task 4: dev-ctx renamed..."
if [ -f "$MASTER" ]; then
    if kubectl --kubeconfig=$MASTER config get-contexts | grep -q "development-context"; then
        if ! kubectl --kubeconfig=$MASTER config get-contexts | grep -q "dev-ctx"; then
            echo "✅ Task 4 Pass: Context successfully renamed to development-context."
            ((SCORE++))
        else
            echo "❌ Task 4 Fail: development-context exists, but dev-ctx was not removed."
        fi
    else
        echo "❌ Task 4 Fail: development-context not found."
    fi
fi

echo "Checking Task 5: db-context.txt populated via JSONPath..."
if [ -f "/opt/course/kube3/db-context.txt" ]; then
    VAL=$(cat /opt/course/kube3/db-context.txt | tr -d '[:space:]')
    if [ "$VAL" == "test-ctx" ]; then
        echo "✅ Task 5 Pass: Correct context identified."
        ((SCORE++))
    else
        echo "❌ Task 5 Fail: db-context.txt contains '$VAL', expected 'test-ctx'."
    fi
else
    echo "❌ Task 5 Fail: db-context.txt not found."
fi

echo "--------------------------------------"
echo "Final Score: $SCORE / $MAX"
if [ $SCORE -eq $MAX ]; then
    echo "🎉 PERFECT SCORE! You have mastered kubeconfigs."
else
    echo "Review the failing tasks. Speed is key!"
fi