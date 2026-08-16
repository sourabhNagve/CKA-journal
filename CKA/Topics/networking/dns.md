# Service Discovery

## Internal Service Discovery

Kubernetes Services can be accessed using their DNS name:

    <service-name>.<namespace>.svc.cluster.local

Example:

    app-9000-service.fubar.svc.cluster.local

The parts are:

- `<service-name>` → Name of the Service
- `<namespace>` → Namespace where the Service exists
- `svc` → Indicates that this is a Kubernetes Service
- `cluster.local` → Default cluster domain

## Connecting to External Services

To give Pods a Kubernetes-internal name for an external service, use a Service of type `ExternalName`.

It acts as a DNS alias. CoreDNS returns a **CNAME** pointing to the external FQDN.

Example:

    apiVersion: v1
    kind: Service
    metadata:
      name: my-database
      namespace: production
    spec:
      type: ExternalName
      externalName: db1.xyz.eu-west-1.rds.amazonaws.com

Pods can then use:

    my-database.production.svc.cluster.local

Kubernetes/CoreDNS resolves this to:

    db1.xyz.eu-west-1.rds.amazonaws.com

## Testing Service Connectivity

Interactive command:

    kubectl exec -it internal-client -n internal -- wget app-9000-service.fubar.svc.cluster.local:9000

For a cleaner connectivity test:

    kubectl exec -n internal internal-client -- wget -qO- --timeout=2 app-9000-service.fubar.svc.cluster.local:9000

The first command may show extra output because `wget` is running interactively with `-it`.

### Useful `wget` Options

| Option | What it does |
|---|---|
| `-q` | Quiet mode; suppresses progress/output |
| `-O-` | Sends the response to stdout |
| `--timeout=2` | Stops waiting after 2 seconds |

### Remember

    Internal Service
    <service>.<namespace>.svc.cluster.local
              ↓
          Kubernetes Service
              ↓
           Endpoints

    ExternalName Service
              ↓
           CNAME
              ↓
      External FQDN