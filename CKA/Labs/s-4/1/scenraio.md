# 1. Exam Scenario

Task:
You have been tasked with upgrading the cluster's primary node. Before you can upgrade the OS packages, you must safely evacuate all workloads from the node.

However, a naive `kubectl drain` command is currently failing or hanging indefinitely due to multiple stubborn workloads deployed in the `upgrade-prep` namespace.

Troubleshoot the workloads and execute the drain command successfully.

When fully operational (ready for upgrade):
1. The node must be cordoned (`SchedulingDisabled`).
2. The node must be completely evacuated of all non-DaemonSet pods from the `upgrade-prep` namespace. 
3. The `ha-app` deployment must maintain its strict PodDisruptionBudget (which requires 2 pods to be available at all times) during the drain. 

# 2. Initial Cluster State

- **Namespaces:** `upgrade-prep`
- **Deployments:** `ha-app`, `local-cache`
- **Pods (Unmanaged):** `legacy-job`
- **DaemonSets:** `node-monitor`
- **PodDisruptionBudgets:** `ha-app-pdb`

# 6. Expected kubectl Outputs

**Command:** `kubectl drain <node-name>`
```text
error: unable to drain node "<node-name>", aborting command...
There are pending nodes to be drained:
 <node-name>
error: cannot delete Pods with local storage...
error: cannot delete Pods not managed by ReplicationController, ReplicaSet, Job, DaemonSet or StatefulSet...
error: cannot delete DaemonSet-managed Pods...

(Note: Once you bypass the flag errors, the drain will hang indefinitely because the ha-app-pdb blocks the eviction. You must satisfy the PDB to complete the drain).

7. Difficulty
10/10

8. Skills Tested
Node Maintenance (cordon, drain, uncordon)

Drain Flags (--ignore-daemonsets, --delete-emptydir-data, --force)

PodDisruptionBudgets (PDB) Troubleshooting

Workload Scaling

9. Constraints
Do NOT delete the ha-app-pdb PodDisruptionBudget. You must satisfy its constraints (by scaling the deployment) so the eviction is naturally allowed.

You must use the correct flags on the kubectl drain command to handle the unmanaged pod, the local storage, and the DaemonSet.

Leave the node cordoned at the end of the exercise (as if you were about to type apt-get upgrade).

10. Time Estimate
15 - 20 minutes