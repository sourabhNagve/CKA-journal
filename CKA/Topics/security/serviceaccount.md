# Service Account Token

Pods run under a **ServiceAccount**, not directly as users.

- If a Pod does not specify a ServiceAccount, Kubernetes uses the namespace's **default ServiceAccount**.
- ServiceAccounts provide an identity that Pods can use when communicating with the Kubernetes API.
- Kubernetes can automatically mount a ServiceAccount token into the Pod.
- The token is used to authenticate API requests, while **RBAC** determines what the ServiceAccount is allowed to do.

The token is typically available at:

    /var/run/secrets/kubernetes.io/serviceaccount/token

The CA certificate is available at:

    /var/run/secrets/kubernetes.io/serviceaccount/ca.crt

Example API request from inside a Pod:

    TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

    curl -s \
      --header "Authorization: Bearer $TOKEN" \
      --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
      https://kubernetes.default.svc/api

## Security Note

Not every Pod needs to communicate with the Kubernetes API.

If the application does not need API access, disable automatic token mounting:

    automountServiceAccountToken: false

This reduces the risk of a compromised application using the Pod's ServiceAccount credentials.