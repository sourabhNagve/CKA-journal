# Gateway API Installation

Gateway API can be installed in different ways depending on whether you want to manage the **CRDs and controller separately** or install everything together.

## 1. Gateway API CRDs + Envoy Gateway Controller Separately

Install the Gateway API CRDs:

    kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml

Install the Envoy Gateway controller:

    helm install eg oci://docker.io/envoyproxy/gateway-helm \
      --version v1.8.3 \
      -n envoy-gateway-system \
      --create-namespace \
      --set crds.enabled=false

The `--set crds.enabled=false` is used because the Gateway API CRDs were already installed separately.

## 2. Install CRDs + Envoy Gateway Using Kubernetes YAML

Envoy Gateway also provides an installation manifest that installs the required CRDs and controller:

    kubectl apply --server-side -f https://github.com/envoyproxy/gateway/releases/download/v1.8.3/install.yaml

## 3. Install Everything Using Helm

The Helm chart can install the Gateway API CRDs and Envoy Gateway controller together:

    helm install eg oci://docker.io/envoyproxy/gateway-helm \
      --version v1.8.3 \
      -n envoy-gateway-system \
      --create-namespace

Wait for the controller:

    kubectl wait --timeout=5m \
      -n envoy-gateway-system \
      deployment/envoy-gateway \
      --for=condition=Available

Apply the Envoy Gateway quickstart example:

    kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.8.3/quickstart.yaml -n default

## 4. Install CRDs Separately Using Helm

If you want to use Helm but keep the CRDs separate:

    helm template eg oci://docker.io/envoyproxy/gateway-crds-helm \
      --version v1.8.3 \
      --set crds.gatewayAPI.enabled=true \
      --set crds.gatewayAPI.channel=standard \
      --set crds.envoyGateway.enabled=true \
      | kubectl apply --server-side -f -

Then install the Envoy Gateway controller without CRDs:

    helm install eg oci://docker.io/envoyproxy/gateway-helm \
      --version v1.8.3 \
      -n envoy-gateway-system \
      --create-namespace \
      --set crds.enabled=false

## Ingress Controller — Traefik

Add the Traefik Helm repository:

    helm repo add traefik https://traefik.github.io/charts
    helm repo update

Create the namespace:

    kubectl create namespace traefik

Install Traefik:

    helm install traefik traefik/traefik \
      --namespace traefik

Documentation:

https://doc.traefik.io/traefik/setup/kubernetes/

## Quick Reminder

    Gateway API
        ↓
    Gateway API CRDs
        ↓
    Gateway Controller (Envoy, Traefik, etc.)
        ↓
    Gateway / HTTPRoute / other Gateway API resources