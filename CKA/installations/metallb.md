# MetalLB

MetalLB provides `LoadBalancer` IPs for Kubernetes clusters that do not have a cloud load balancer.

## Installation

Install MetalLB:

    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml

Watch MetalLB Pods:

    kubectl get pods -n metallb-system --watch

Check node IPs:

    kubectl get nodes -o wide

MetalLB needs a pool of IP addresses to assign to `LoadBalancer` Services.

In environments like KillerCoda, choose IPs from the same network range as the Kubernetes nodes. Check the `INTERNAL-IP` column to determine the appropriate range.

## IPAddressPool

An `IPAddressPool` defines the IP addresses MetalLB can allocate to Services.

Example:

    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: first-pool
      namespace: metallb-system
    spec:
      addresses:
        - 192.168.1.240-192.168.1.250

Multiple address formats can be used:

    addresses:
      - 192.168.10.0/24
      - 192.168.9.1-192.168.9.5
      - fc00:f853:0ccd:e799::/124

All IPs defined in `IPAddressPool` resources form the pool MetalLB uses to assign IPs to `LoadBalancer` Services.

## L2Advertisement

An `L2Advertisement` tells MetalLB which IPs should be advertised using Layer 2.

    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: example
      namespace: metallb-system
    spec:
      ipAddressPools:
        - first-pool

If `ipAddressPools` is omitted, the advertisement applies to all available `IPAddressPool` resources.

Use `ipAddressPools` when you want to advertise only specific pools.

## Flow

    LoadBalancer Service
            ↓
       MetalLB
            ↓
      IPAddressPool
            ↓
      Assigns an IP
            ↓
       L2Advertisement
            ↓
       Service gets
       external IP