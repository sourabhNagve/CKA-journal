# API Request Components

A Kubernetes API request commonly contains:

    curl --cacert ca.cert \
      -H "Authorization: Bearer $TOKEN" \
      https://API_SERVER:6443/api/v1/namespaces/NAMESPACE/pods/

- `--cacert ca.cert` → CA certificate used to verify the API server's TLS certificate.
- `Authorization: Bearer $TOKEN` → Authentication credentials.
- `https://API_SERVER:6443` → Kubernetes API server endpoint.
- `/api/v1/namespaces/NAMESPACE/pods/` → API resource path for Pods in a specific namespace.

## General Structure

    curl [TLS options] [authentication] https://API_SERVER:6443/[API path]