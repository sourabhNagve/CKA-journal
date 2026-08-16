# RBAC

**RBAC (Role-Based Access Control)** is Kubernetes' authorization mechanism. It controls **who** (user or ServiceAccount) can access **what** resources (Pods, Deployments, Secrets, etc.) and **which actions** (`get`, `list`, `delete`, etc.) they can perform.

## RBAC Resources

| Resource | Scope | Purpose |
|---|---|---|
| **Role** | Namespace | Defines permissions within one namespace |
| **ClusterRole** | Cluster | Defines permissions across namespaces or for cluster-scoped resources |
| **RoleBinding** | Namespace | Grants a Role or ClusterRole to users/ServiceAccounts within a namespace |
| **ClusterRoleBinding** | Cluster | Grants a ClusterRole across the entire cluster |

## RBAC Best Practices

| Practice | Why |
|---|---|
| **Least privilege** | Grant only the permissions required |
| **Namespace-level scoping** | Prefer RoleBindings over ClusterRoleBindings where possible |
| **Avoid wildcards** | Avoid `resources: ["*"]` and `verbs: ["*"]` |
| **Prefer group bindings** | Easier to manage than binding users individually |
| **Avoid `cluster-admin`** | Use lower-privileged accounts unless absolutely necessary |
| **Avoid `system:masters`** | Members bypass normal RBAC authorization checks |
| **Review periodically** | Remove unused Roles and RoleBindings |

## Privilege Escalation Risks

Be careful when granting these permissions:

| Permission | Risk |
|---|---|
| `list/watch` on Secrets | Can expose Secret contents |
| `create` on Pods/workloads | Pods may be created to access Secrets, ConfigMaps, or other resources |
| `create` on PersistentVolumes | Can potentially create `hostPath` volumes and access the host filesystem |
| `get` on `nodes/proxy` | Can provide access to the kubelet API |
| `escalate` | Allows creating/updating Roles with permissions beyond your own |
| `bind` | Allows binding to Roles/ClusterRoles you could not otherwise grant |
| `impersonate` | Allows acting as another user, group, or ServiceAccount |

## Remember

```text
Role              → Defines permissions
ClusterRole       → Defines cluster-wide permissions
RoleBinding       → Grants permissions within a namespace
ClusterRoleBinding → Grants permissions cluster-wide