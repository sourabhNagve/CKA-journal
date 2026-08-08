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



------------------------------------------------------------------------------
HTTPRoute mirroring means sending a copy of incoming requests to a second backend for testing or observation, while the client still gets the response from the main backend.

What it does
The primary backend handles the real response.

The mirrored backend receives a best-effort copy of the request.

The mirrored response is ignored by the Gateway.

Why use it
Test a new version in production without affecting users.

Compare behavior, logs, or performance of a canary service.

Validate changes before shifting real traffic.


------------------------------------------
You use a ReferenceGrant in the Kubernetes Gateway API when you need to allow cross‑namespace references between Gateway API objects (Routes, Gateways, Secrets, Services, etc.).