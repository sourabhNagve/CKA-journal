# Authorization

**Authorization** determines whether a user, ServiceAccount, or system component has permission to perform a specific **verb** on a specific **resource** in the cluster.

## Authorization Modes

Configured in the kube-apiserver using:

    --authorization-mode

### Node

- Special-purpose authorizer for **kubelets**.
- Restricts kubelet access to resources related to the node it runs on.
- Example: kubelet on `node-1` can access Pods assigned to `node-1`.

### RBAC

- Primary authorization method in most Kubernetes clusters.
- Uses **Roles/RoleBindings** and **ClusterRoles/ClusterRoleBindings**.
- Provides fine-grained control over resources and verbs such as `get`, `list`, `create`, and `delete`.

### Webhook

- Delegates authorization decisions to an external service.
- Useful for custom authorization policies.

### AlwaysDeny

- Denies every request.
- Mainly useful for testing or emergency lockdowns.

### AlwaysAllow

- Allows every request without authorization checks.
- Useful only for local/testing environments.
- **Not safe for production.**

## Authorization Evaluation

When multiple modes are configured:

    --authorization-mode=Node,RBAC,Webhook

Kubernetes checks them in the configured order.

The important concept is:

    Request
      ↓
    Node
      ↓
    RBAC
      ↓
    Webhook

A mode can:

- **Allow** → request is approved.
- **Deny** → request is rejected.
- **No opinion** → Kubernetes checks the next authorizer.

## Examples

### Node Authorizer

Kubelet on `node-1` requests a Pod running on `node-1`:

    Node → Allow

Kubelet on `node-1` tries to access resources belonging to `node-2`:

    Node → Deny

### RBAC

Developer runs:

    kubectl get pods

If their Role allows `get`:

    RBAC → Allow

If their Role only allows `get` and `list` and they run:

    kubectl delete deployment app

    RBAC → Deny

### Webhook

A cluster can delegate authorization to an external policy service for custom rules that Kubernetes RBAC does not provide.

## Cheat Sheet

    Node      → Kubelet-specific authorization
    RBAC      → Roles and bindings
    Webhook   → External/custom authorization
    AlwaysDeny → Deny everything
    AlwaysAllow → Allow everything

**Remember:** Authorization answers the question:

> "Is this identity allowed to perform this action on this resource?"