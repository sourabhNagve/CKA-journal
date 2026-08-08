# 1. Exam Scenario

Task:
A deployment named `cluster-scraper` in the `observability` namespace is designed to collect metrics by querying the Kubernetes API for cluster-wide resources (specifically, `nodes` and `namespaces`). 

Currently, the deployment is completely failing to run. 

Troubleshoot and resolve all issues preventing the `cluster-scraper` pods from successfully executing their scripts. You will need to resolve scheduling issues, configuration errors, and authorization failures.

When fully operational, the pod should reach the `Running` state and its logs must display `SUCCESS: Cluster metrics gathered.`

# 2. Initial Cluster State

- **Namespaces:** `observability`
- **Deployments:** `cluster-scraper` (in `observability`)
- **ServiceAccounts:** `scraper-sa` (in `observability`)
- **ConfigMaps:** `scraper-config` (in `observability`)
- **Roles:** `scraper-role` (in `observability`)
- **RoleBindings:** `scraper-binding` (in `observability`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n observability`
```text
NAME                               READY   STATUS    RESTARTS   AGE
cluster-scraper-7b9c9d5d9b-abcde   0/1     Pending   0          2m14s

cluster-scraper-7b9c9d5d9b-abcde   0/1     Pending   0          2m14s
Command: kubectl describe pod -n observability -l app=scraper

Plaintext
...
Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  2m20s  default-scheduler  0/2 nodes are available: 2 node(s) didn't match Pod's node affinity/selector.
(Note: Once you resolve the scheduling issue, the pod will transition to a CrashLoopBackOff. Investigating the logs will reveal missing configuration files and API permission errors (HTTP 403) that you must also resolve).

7. Difficulty
8.5/10

8. Skills Tested
Pod Scheduling (nodeSelector & Node Labels)

Volume Mount Paths (ConfigMaps)

Advanced RBAC (Role vs ClusterRole for cluster-scoped resources)

Pod Troubleshooting via Logs

9. Constraints
Do NOT remove the nodeSelector from the deployment. Instead, modify the cluster environment to satisfy it.

Do NOT delete the cluster-scraper Deployment; modify it in place.

Ensure the scraper-sa ServiceAccount uses the principle of least privilege. Do NOT grant it cluster-admin. It only needs get and list permissions for nodes and namespaces.

The pod relies on a configuration file being present at /etc/scraper/config.yaml.

10. Time Estimate
15 - 20 minutes