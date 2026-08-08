#!/bin/bash

SCORE=0
MAX=7
NEW_CONF="/opt/course/kube4/custom-config.yaml"

echo "Checking Task 1: Cluster created and CA embedded..."
if [ -f "$NEW_CONF" ]; then
    SERVER=$(kubectl --kubeconfig=$NEW_CONF config view -o jsonpath='{.clusters[?(@.name=="omega-cluster")].cluster.server}')
    CA_DATA=$(kubectl --kubeconfig=$NEW_CONF config view --raw -o jsonpath='{.clusters[?(@.name=="omega-cluster")].cluster.certificate-authority-data}')
    
    if [ "$SERVER" == "https://172.16.0.100:6443" ] && [ -n "$CA_DATA" ]; then
        echo "✅ Task 1 Pass: omega-cluster configured and CA is embedded."
        ((SCORE++))
    else
        echo "❌ Task 1 Fail: omega-cluster missing, wrong server URL, or CA not embedded."
    fi
else
    echo "❌ Task 1 Fail: custom-config.yaml not found."
fi

echo "Checking Task 2: cluster-admin user created and certs embedded..."
if [ -f "$NEW_CONF" ]; then
    CERT_DATA=$(kubectl --kubeconfig=$NEW_CONF config view --raw -o jsonpath='{.users[?(@.name=="cluster-admin")].user.client-certificate-data}')
    KEY_DATA=$(kubectl --kubeconfig=$NEW_CONF config view --raw -o jsonpath='{.users[?(@.name=="cluster-admin")].user.client-key-data}')
    
    if [ -n "$CERT_DATA" ] && [ -n "$KEY_DATA" ]; then
        echo "✅ Task 2 Pass: cluster-admin configured with embedded certs."
        ((SCORE++))
    else
        echo "❌ Task 2 Fail: cluster-admin missing or certs/keys are not embedded."
    fi
fi

echo "Checking Task 3: dev-user created with token..."
if [ -f "$NEW_CONF" ]; then
    TOKEN=$(kubectl --kubeconfig=$NEW_CONF config view --raw -o jsonpath='{.users[?(@.name=="dev-user")].user.token}')
    if [ "$TOKEN" == "dev-token-999xyz" ]; then
        echo "✅ Task 3 Pass: dev-user configured with correct token."
        ((SCORE++))
    else
        echo "❌ Task 3 Fail: dev-user missing or token is incorrect."
    fi
fi

echo "Checking Task 4: admin-system context created..."
if [ -f "$NEW_CONF" ]; then
    NS=$(kubectl --kubeconfig=$NEW_CONF config view -o jsonpath='{.contexts[?(@.name=="admin-system")].context.namespace}')
    USR=$(kubectl --kubeconfig=$NEW_CONF config view -o jsonpath='{.contexts[?(@.name=="admin-system")].context.user}')
    
    if [ "$NS" == "kube-system" ] && [ "$USR" == "cluster-admin" ]; then
        echo "✅ Task 4 Pass: admin-system context correctly configured."
        ((SCORE++))
    else
        echo "❌ Task 4 Fail: admin-system context misconfigured."
    fi
fi

echo "Checking Task 5: dev-apps context created..."
if [ -f "$NEW_CONF" ]; then
    NS=$(kubectl --kubeconfig=$NEW_CONF config view -o jsonpath='{.contexts[?(@.name=="dev-apps")].context.namespace}')
    USR=$(kubectl --kubeconfig=$NEW_CONF config view -o jsonpath='{.contexts[?(@.name=="dev-apps")].context.user}')
    
    if [ "$NS" == "applications" ] && [ "$USR" == "dev-user" ]; then
        echo "✅ Task 5 Pass: dev-apps context correctly configured."
        ((SCORE++))
    else
        echo "❌ Task 5 Fail: dev-apps context misconfigured."
    fi
fi

echo "Checking Task 6: Active context set..."
if [ -f "$NEW_CONF" ]; then
    CUR=$(kubectl --kubeconfig=$NEW_CONF config current-context)
    if [ "$CUR" == "dev-apps" ]; then
        echo "✅ Task 6 Pass: Current context is dev-apps."
        ((SCORE++))
    else
        echo "❌ Task 6 Fail: Current context is $CUR, expected dev-apps."
    fi
fi

echo "Checking Task 7: Token extracted to file..."
if [ -f /opt/course/kube4/extracted-token.txt ]; then
    VAL=$(cat /opt/course/kube4/extracted-token.txt | tr -d '[:space:]')
    if [ "$VAL" == "dev-token-999xyz" ]; then
        echo "✅ Task 7 Pass: Token correctly extracted using JSONPath."
        ((SCORE++))
    else
        echo "❌ Task 7 Fail: File contains wrong value ($VAL)."
    fi
else
    echo "❌ Task 7 Fail: /opt/course/kube4/extracted-token.txt not found."
fi

echo "--------------------------------------"
echo "Final Score: $SCORE / $MAX"
if [ $SCORE -eq $MAX ]; then
    echo "🎉 PERFECT SCORE! You can build configurations from thin air."
else
    echo "Keep practicing your imperative config commands!"
fi