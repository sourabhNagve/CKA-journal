# 1. Exam Scenario

Task:
A deployment named `api-server` exists in the `finance-api` namespace. It relies on a database running in the `finance-db` namespace. 

Currently, the `api-server` pods are failing to start. 

Troubleshoot and resolve the issues preventing the `api-server` deployment from reaching the `Running` state. Ensure that the `api-server` pods can successfully communicate with the `postgres-db` pod via the `postgres-svc` service.

Additionally, the security team requires that the existing ServiceAccount `db-troubleshooter` in the `finance-db` namespace be granted specific permissions to aid in future debugging. Grant this ServiceAccount permissions to ONLY `get`, `list`, and `watch` pods, and to execute commands inside pods (`pods/exec`) within the `finance-db` namespace.
---------------------------------------------------------
# 2. Initial Cluster State

- **Namespaces:** `finance-api`, `finance-db`, `frontend-web`
- **Deployments:** `api-server` (in `finance-api`)
- **Pods:** `postgres-db` (in `finance-db`)
- **Services:** `postgres-svc` (in `finance-db`)
- **NetworkPolicies:** `allow-api-to-db` (in `finance-db`)
- **ServiceAccounts:** `db-troubleshooter` (in `finance-db`)
- **ConfigMaps:** `dummy-config` (in `finance-api`)
- **Secrets:** `dummy-secret` (in `finance-db`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n finance-api`

NAME                          READY   STATUS     RESTARTS   AGE
api-server-6b586d99b6-abcde   0/1     Init:0/1   0          4m22s

-------------------------------------------------------
8. Skills Tested
Advanced Troubleshooting

Networking & NetworkPolicies

Services and Label Selectors

InitContainers

RBAC (Roles, RoleBindings, Subresources)
-------------------------------------------------------
9. Constraints
Do NOT delete or recreate existing namespaces.

Do NOT delete the postgres-svc service; you must modify it in place.

Do NOT delete the allow-api-to-db NetworkPolicy; modify the environment or the policy to satisfy its requirements.

Existing Pods in finance-db must remain running.

You must follow the principle of least privilege for the RBAC task.