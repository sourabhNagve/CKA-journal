# 1. Exam Scenario

Task:
A deployment named `data-analyzer` exists in the `data-processing` namespace. It runs a data processing script that sequentially tests storage access, allocates memory, and finally queries the Kubernetes API to retrieve a list of pods in its namespace.

Currently, the deployment is completely failing to complete its tasks and is stuck in a restart loop.

Troubleshoot and resolve all issues preventing the `data-analyzer` pod from successfully executing its script. You must resolve the issues systematically as they appear.

When fully operational, the pod should reach the `Running` state and log `SUCCESS: All tests passed.`

# 2. Initial Cluster State

- **Namespaces:** `data-processing`
- **Deployments:** `data-analyzer` (in `data-processing`)
- **ServiceAccounts:** `analyzer-sa`, `default` (in `data-processing`)
- **Roles:** `pod-reader` (in `data-processing`)
- **RoleBindings:** `analyzer-binding` (in `data-processing`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n data-processing`
```text
NAME                             READY   STATUS             RESTARTS      AGE
data-analyzer-6b586d99b6-abcde   0/1     CrashLoopBackOff   4 (32s ago)   2m14s

Command: kubectl logs -n data-processing deploy/data-analyzer

Plaintext
Testing write access...
Permission denied writing to /data
(Note: Once you fix the write access, you will encounter additional errors such as OOMKilled and API authorization failures that you must also resolve).

7. Difficulty
9.5/10

8. Skills Tested
Pod SecurityContexts (fsGroup, runAsUser)

Container Resource Limits & Troubleshooting OOMKilled

Ephemeral Volumes (emptyDir / tmpfs)

RBAC (Roles, RoleBindings, and ServiceAccounts)

9. Constraints
Do NOT delete the data-analyzer Deployment; modify it in place.

Do NOT remove runAsUser: 1000 from the Pod's SecurityContext.

Do NOT change the container image or modify the inline bash script inside command/args.

Adhere to the principle of least privilege. Do not bind the cluster-admin role or grant unnecessary permissions.

The Deployment must continue to use the data-vol volume.