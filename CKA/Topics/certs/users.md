# Kubernetes Users

Kubernetes does **not** have a built-in User object like Linux does.

- We don't create a user record inside the Kubernetes cluster.
- A user is authenticated through an **external identity mechanism**.
- One common method is **client certificates**.
- The username can come from the certificate's subject, such as the **Common Name (CN)**.
- The certificate proves the identity of the user to the Kubernetes API server.
- After authentication, **RBAC** controls what the user is allowed to do.
- Permissions are granted using **Roles/ClusterRoles** and **RoleBindings/ClusterRoleBindings**, not through a Kubernetes User object.

```text
User
  ↓
Client Certificate
  ↓
Authentication
  ↓
Kubernetes API Server
  ↓
RBAC
  ↓
Role / ClusterRole
  ↓
Allowed or Denied

Important
Authentication → Who are you?
Authorization  → What are you allowed to do?