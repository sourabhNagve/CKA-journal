# Gateway API

The **Gateway API** provides a more expressive, extensible, and role-oriented way to manage traffic routing in Kubernetes.

## Main Components

### GatewayClass

Defines the type of Gateway controller, such as NGINX, Istio, or Envoy.

- Cluster-scoped
- Similar to `StorageClass` or `IngressClass`
- Usually managed by a cluster administrator

### Gateway

Defines the actual gateway infrastructure and listeners.

- Namespace-scoped
- Defines ports and protocols
- Can configure TLS
- Can be shared by multiple Routes

### HTTPRoute

Defines HTTP traffic-routing rules.

- Namespace-scoped
- Supports path, header, and query-parameter matching
- References backend Services
- Usually managed by application developers

### ReferenceGrant

Controls which resources can be referenced across namespaces.

- Namespace-scoped
- Used to allow specific cross-namespace references
- Prevents arbitrary cross-namespace access

## Traffic Flow

    Internet Traffic (HTTPS)
             ↓
         [Gateway]
       TLS Termination
             ↓
        [HTTPRoute]
       Routing Rules
             ↓
       ┌─────┬──────┬──────────┐
       │     │      │          │
    /available /books /travellers
       │     │      │          │
       ↓     ↓      ↓          ↓
    [Service][Service][Service]
       │     │      │
       ↓     ↓      ↓
     [Pods] [Pods] [Pods]

## Roles

    Cluster Admin
         ↓
    GatewayClass
    (Which controller?)

    Platform / Namespace Admin
         ↓
    Gateway
    (Gateway infrastructure)

    Application Developer
         ↓
    HTTPRoute / GRPCRoute / TCPRoute
    (Traffic routing)

---

## HTTPRoute Traffic Mirroring

**HTTPRoute mirroring** sends a copy of incoming requests to a secondary backend while the primary backend continues handling the real response.

### What It Does

- Primary backend handles the actual response.
- Mirrored backend receives a best-effort copy of the request.
- The mirrored response is ignored.

### Why Use It?

- Test a new version without affecting users.
- Compare behavior, logs, or performance.
- Validate a new service before shifting real traffic.

    Client
      │
      ├──────────────→ Primary Backend
      │                    ↓
      │                 Response
      │
      └─── copy ──────→ Mirror Backend
                           ↓
                      Response ignored

---

## ReferenceGrant

Use a **ReferenceGrant** when a Gateway API resource needs to reference an allowed resource in another namespace.

For example:

    HTTPRoute (namespace A)
             ↓
       ReferenceGrant
             ↓
    Service (namespace B)

The ReferenceGrant provides an explicit permission for the cross-namespace reference.

### Remember

    GatewayClass → Defines the Gateway controller
    Gateway      → Defines the Gateway infrastructure
    HTTPRoute    → Defines traffic routing
    ReferenceGrant → Allows specific cross-namespace references