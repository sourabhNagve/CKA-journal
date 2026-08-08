installation of gateway.

installing the gateway and controller separately
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml

gateway api controller
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.8.3 \
  -n envoy-gateway-system \
  --create-namespace \
  --set crds.enabled=false

----------------------------------------------------------

install both the crds using kubernetes yaml using the below command:
kubectl apply --server-side -f https://github.com/envoyproxy/gateway/releases/download/v1.8.3/install.yaml



helm way:
gatewaycrds + controller
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.8.3 -n envoy-gateway-system --create-namespace
kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.8.3/quickstart.yaml -n default 

--------------------------------------------------------------------------------------
Using helm but separately:
helm template eg oci://docker.io/envoyproxy/gateway-crds-helm \
  --version v1.8.3 \
  --set crds.gatewayAPI.enabled=true \
  --set crds.gatewayAPI.channel=standard \
  --set crds.envoyGateway.enabled=true \
  | kubectl apply --server-side -f -

-----------------------------------------------------
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.8.3 \
  -n envoy-gateway-system \
  --create-namespace \
  --set crds.enabled=false







--------------------------------------------------------------------------------------------------------------------
Now ingress controller
helm repo add traefik https://traefik.github.io/charts
helm repo update
kubectl create namespace traefik
https://doc.traefik.io/traefik/setup/kubernetes/