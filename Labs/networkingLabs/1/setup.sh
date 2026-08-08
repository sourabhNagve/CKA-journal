#!/bin/bash
# setup-scenario.sh
# This script sets up "The Gateway API Canary & DNS Blackhole" scenario.

echo "🚀 Starting scenario setup..."

# 2. Deploy api-v1 and api-v2 Deployments
echo "🚀 Deploying microservices..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-v1
  labels:
    app: api-v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-v1
  template:
    metadata:
      labels:
        app: api-v1
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo
        args:
        - "-text=api-v1-healthy"
        ports:
        - containerPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-v2
  labels:
    app: api-v2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-v2
  template:
    metadata:
      labels:
        app: api-v2
    spec:
      containers:
      - name: app
        image: hashicorp/http-echo
        args:
        - "-text=api-v2-canary"
        ports:
        - containerPort: 5678
EOF

# 3. Create Services (api-v2 is intentionally broken)
echo "🔗 Creating Services (Injecting label mismatch bug for api-v2)..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: api-v1
spec:
  selector:
    app: api-v1
  ports:
  - port: 80
    targetPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: api-v2
spec:
  # BUG: Label mismatch. This should be 'app: api-v2'
  selector:
    app: api-v2-broken 
  ports:
  - port: 80
    targetPort: 5678
EOF

# 4. Create GatewayClass, Gateway, and HTTPRoute (Misconfigured)
echo "🔀 Configuring Gateway API (Injecting HTTPRoute bugs)..."
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: example-gateway-class
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prod-gateway
  namespace: default
spec:
  gatewayClassName: example-gateway-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api-canary-route
  namespace: default
spec:
  parentRefs:
  - name: prod-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: api-v1
      port: 80
      weight: 50  # BUG: Needs to be 70
    - name: api-v2-typo # BUG: Invalid backend reference name
      port: 80
      weight: 50  # BUG: Needs to be 30
EOF

# 5. Inject the CoreDNS Bug
echo "💥 Breaking CoreDNS to simulate DNS blackhole..."
# Extract current coredns config
kubectl get configmap coredns -n kube-system -o yaml > /tmp/coredns-original.yaml

# We inject an invalid plugin block 'dns_blackhole_plugin' that causes CoreDNS to fail parsing
sed 's/kubernetes cluster.local in-addr.arpa ip6.arpa {/dns_blackhole_plugin_invalid {\n           drop_all\n        }\n        kubernetes cluster.local in-addr.arpa ip6.arpa {/' /tmp/coredns-original.yaml > /tmp/coredns-broken.yaml

kubectl apply -f /tmp/coredns-broken.yaml

# Restart CoreDNS so the broken config takes effect (they will CrashLoopBackOff)
kubectl rollout restart deployment coredns -n kube-system

echo "========================================================"
echo "✅ Scenario setup complete!"
echo "Cluster is now in a broken state:"
echo " - CoreDNS pods are crashing/failing due to an invalid plugin."
echo " - api-v2 Service has no endpoints."
echo " - api-canary-route HTTPRoute is misconfigured."
echo "========================================================"