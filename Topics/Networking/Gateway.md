# gateway api offers more expressive, extensible and role-oriented api for managing traffic routing.
components are:

- GatewayClass
Defines the type of Gateway controller (e.g., NGINX, Istio, Envoy)
Cluster-scoped resource
Similar to StorageClass or IngressClass

- Gateway
Defines the infrastructure (load balancer, listeners)
Specifies protocols, ports, TLS configuration
Can be shared across multiple routes
Namespace-scoped

- httpRoute

Defines HTTP traffic routing rules
Path-based routing, header matching, query parameters
References backend Services
Namespace-scoped


- ReferenceGrant

Enables cross-namespace references
Security control for service access
Allows HTTPRoute in one namespace to reference Services in another

Diagram:
Internet Traffic (HTTPS)
         ↓
    [Gateway]
    (TLS Termination)
         ↓
    [HTTPRoute]
    (Path-based Routing)
         ↓
    ┌────────┬──────────┬──────────┐
    │        │          │          │
/available  /books  /travellers
    │        │          │          │
    ↓        ↓          ↓          ↓
[Service]  [Service]  [Service]
available   books    travellers
    │        │          │          │
    ↓        ↓          ↓          ↓
[Pods]     [Pods]     [Pods]

Cluster admin → manages GatewayClass (defines the controller, e.g. NGINX, Envoy)

Namespace admin / operator → manages Gateway (an actual gateway instance)

App developer → manages routes like HTTPRoute, GRPCRoute, TCPRoute