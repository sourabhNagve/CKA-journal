# Ingress Controller

An **Ingress Controller** is a Kubernetes component that acts as an entry point for external HTTP/HTTPS traffic.

- Usually runs as a Pod/Deployment in the cluster.
- Receives HTTP/HTTPS requests from users.
- Reads the **host and path** from the request.
- Finds the matching **Ingress** resource.
- Routes the request to the appropriate backend Service.

## TLS Termination

With TLS termination, the **Ingress Controller handles HTTPS encryption/decryption** instead of the backend applications.

    User
      │
      │ HTTPS (encrypted)
      ▼
    Ingress
      │
      │ HTTP (decrypted)
      ▼
    Backend Service

The Ingress Controller uses a Kubernetes **TLS Secret** containing:

- TLS certificate
- Private key

For example:

    ua-heroes-tls

### What Happens?

1. User sends an HTTPS request.
2. Ingress receives the encrypted request.
3. Ingress uses the certificate from the TLS Secret.
4. Ingress decrypts the request.
5. Ingress forwards the request as HTTP to the backend Service.

Backend Pods therefore do not need to manage TLS certificates themselves.

### Why Use TLS Termination?

- Centralizes TLS handling at the Ingress.
- Backend applications can use simple HTTP.
- Certificates don't need to be configured in every backend application.

## Resource Scope

    IngressClass → Cluster-scoped
    Ingress      → Namespace-scoped

## Testing

    curl -k -v https://heroes.ua-academy.com/register | jq

- `-k` → Ignore certificate verification.
- `-v` → Show detailed request/response information.
- `| jq` → Format JSON output.