# Services and Endpoints

When you create a Service with a **selector**, Kubernetes looks for Pods whose labels match that selector and populates **EndpointSlices** with their IP addresses and ports.

If no Pods match the selector, or the matching Pods are not ready, the EndpointSlice can have no usable endpoints and the Service has nowhere to send traffic.

## Traffic Flow

The actual traffic path is:

    Service DNS / ClusterIP
            ↓
       kube-proxy
            ↓
      EndpointSlice
            ↓
       Pod IP:Port

EndpointSlices are **not a middlebox** that carries traffic. They act as the backend address book that Kubernetes networking uses to determine where Service traffic should go.

## Multiple Service CIDRs

Kubernetes supports adding an additional Service CIDR using the `ServiceCIDR` API.

This allows Services to receive ClusterIPs from an additional address range without changing the existing API server configuration.

The general flow is:

    1. Create a new ServiceCIDR.
    2. Create a Service.
    3. Manually specify a ClusterIP from the new ServiceCIDR.
    4. Kubernetes assigns that IP to the Service.

Example:

    apiVersion: networking.k8s.io/v1
    kind: ServiceCIDR
    metadata:
      name: new-service-cidr
    spec:
      cidrs:
        - 10.100.0.0/16

Then a Service can explicitly request an IP from that range:

    spec:
      clusterIP: 10.100.0.10