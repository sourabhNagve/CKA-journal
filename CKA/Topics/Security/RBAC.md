RBAC- it is k8s authorization mechanism that controls who(service account or user) can access what resources(pods, deployments etc) and what actions(get, list, delete etc) they can perform based on assigned roles.

Roles- namespace scoped , permission within a namespace
clusterRole- clusterwide, permission across all namespaces or on cluster scoped resources.
Rolebinding- namespaced , grants role/ clusteRole permissions within a ns.
clusterRoleBinding- clusterwide, grants clusterRole permissions across entire cluster.

✅ RBAC Best Practices
| Practice                    | Why                                                                 |
| --------------------------- | ------------------------------------------------------------------- |
| Least privilege             | Grant only required permissions kubernetes                          |
| Namespace-level scoping     | Use RoleBindings over ClusterRoleBindings where possible kubernetes |
| Avoid wildcards             | Don't use resources: ["*"] or verbs: ["*"] kubernetes               |
| Prefer group bindings       | Easier to manage than individual users youtube                      |
| Avoid cluster-admin         | Use lower-privileged accounts unless absolutely needed kubernetes   |
| Don't add to system:masters | Bypasses all RBAC checks permanently kubernetes                     |
| Periodic review             | Remove unused bindings regularly kubernetes                         |

⚠️ Privilege Escalation Risks
Avoid granting these unless necessary:
| Permission                  | Risk                                                            |
| --------------------------- | --------------------------------------------------------------- |
| list/watch on secrets       | Reveals secret contents kubernetes                              |
| create on workloads (Pods)  | Can mount secrets/ConfigMaps; gain API access kubernetes        |
| create on PersistentVolumes | Can create hostPath volumes → host filesystem access kubernetes |
| get on nodes/proxy          | Access kubelet API; execute/attach to pods kubernetes           |
| escalate verb               | Create roles with more rights than you have kubernetes          |
| bind verb                   | Bind to roles you don't have kubernetes                         |
| impersonate verb            | Gain rights of other users kubernetes                           |


