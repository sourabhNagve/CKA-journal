# kubectl proxy

`kubectl proxy` creates a local proxy to the Kubernetes API server using your existing kubeconfig credentials.

You do **not** need to manually provide a ServiceAccount token, client certificate, or CA certificate.

Start the proxy:

    kubectl proxy --port 8080

Then access the Kubernetes API through localhost:

    curl http://127.0.0.1:8080/api/v1/namespaces/{namespace}/secrets

Example:

    curl http://127.0.0.1:8080/api/v1/namespaces/default/secrets

The flow is:

    curl
      ↓
    localhost:8080
      ↓
    kubectl proxy
      ↓
    Kubernetes API Server

`kubectl proxy` handles authentication to the API server using your current kubeconfig context.