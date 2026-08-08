#!/bin/bash

SCORE=0
MAX=6
MERGED_FILE="/opt/course/kubeconfigs/merged.yaml"

echo "Checking Task 1: Merged file exists and contains all clusters..."
if [ -f "$MERGED_FILE" ]; then
    clusters=$(kubectl --kubeconfig=$MERGED_FILE config get-clusters | tail -n +2 | wc -l)
    if [ "$clusters" -eq 3 ]; then 
        echo "✅ Task 1 Pass: Merged file contains all 3 clusters."
        ((SCORE++))
    else
        echo "❌ Task 1 Fail: Clusters missing from merged.yaml. Expected 3, found $clusters."
    fi
else
    echo "❌ Task 1 Fail: merged.yaml not found."
fi

echo "Checking Task 2: Broken cluster fixed..."
if kubectl --kubeconfig=$MERGED_FILE config view -o jsonpath='{.clusters[?(@.name=="cluster-broken")].cluster.server}' | grep -q "6443"; then
    echo "✅ Task 2 Pass: Port fixed to 6443."
    ((SCORE++))
else
    echo "❌ Task 2 Fail: Port not fixed for cluster-broken."
fi

echo "Checking Task 3: dev-user added with file paths..."
user_cert=$(kubectl --kubeconfig=$MERGED_FILE config view -o jsonpath='{.users[?(@.name=="dev-user")].user.client-certificate}')
if [ "$user_cert" == "/opt/course/certs/dev.crt" ]; then
    echo "✅ Task 3 Pass: User dev-user is configured correctly with file paths (not embedded data)."
    ((SCORE++))
else
    echo "❌ Task 3 Fail: User dev-user missing or has wrong/embedded cert path."
fi

echo "Checking Task 4: dev-access context created correctly..."
if kubectl --kubeconfig=$MERGED_FILE config get-contexts dev-access >/dev/null 2>&1; then
    namespace=$(kubectl --kubeconfig=$MERGED_FILE config view -o jsonpath='{.contexts[?(@.name=="dev-access")].context.namespace}')
    user=$(kubectl --kubeconfig=$MERGED_FILE config view -o jsonpath='{.contexts[?(@.name=="dev-access")].context.user}')
    cluster=$(kubectl --kubeconfig=$MERGED_FILE config view -o jsonpath='{.contexts[?(@.name=="dev-access")].context.cluster}')
    
    if [ "$namespace" == "development" ] && [ "$user" == "dev-user" ] && [ "$cluster" == "external-cluster" ]; then
        echo "✅ Task 4 Pass: Context dev-access has correct cluster, user, and namespace."
        ((SCORE++))
    else
        echo "❌ Task 4 Fail: Context dev-access has wrong parameters (NS: $namespace, User: $user, Cluster: $cluster)."
    fi
else
    echo "❌ Task 4 Fail: Context dev-access not found."
fi

echo "Checking Task 5: Current context set..."
current=$(kubectl --kubeconfig=$MERGED_FILE config current-context)
if [ "$current" == "dev-access" ]; then
    echo "✅ Task 5 Pass: Current context is dev-access."
    ((SCORE++))
else
    echo "❌ Task 5 Fail: Current context is $current, expected dev-access."
fi

echo "Checking Task 6: Extracted CA..."
if [ -f /opt/course/certs/internal-ca.crt ]; then
    content=$(cat /opt/course/certs/internal-ca.crt)
    if [ "$content" == "this is the internal ca data" ]; then
        echo "✅ Task 6 Pass: CA correctly extracted and decoded."
        ((SCORE++))
    else
        echo "❌ Task 6 Fail: CA content is incorrect or not correctly base-64 decoded."
    fi
else
    echo "❌ Task 6 Fail: CA file not found."
fi

echo "--------------------------------------"
echo "Final Score: $SCORE / $MAX"
if [ $SCORE -eq $MAX ]; then
    echo "🎉 PERFECT SCORE! You are ready for the exam."
else
    echo "Keep practicing! Review the failing tasks."
fi