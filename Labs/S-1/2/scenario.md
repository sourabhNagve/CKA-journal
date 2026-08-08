# 1. Exam Scenario

Task:
A StatefulSet named `web-cache` in the `data-ops` namespace was recently scaled from 1 to 2 replicas to handle increased traffic. However, the new replica (`web-cache-1`) is stuck in the `Pending` state.

Troubleshoot and resolve all issues preventing the `web-cache-1` pod from reaching the `Running` state and successfully binding to its persistent volume.

# 2. Initial Cluster State

- **Namespaces:** `data-ops`
- **StatefulSets:** `web-cache` (in `data-ops`)
- **Pods:** `web-cache-0` (Running), `web-cache-1` (Pending)
- **PVCs:** `data-web-cache-0` (Bound), `data-web-cache-1` (Pending)
- **PVs:** `pv-cache-0`, `pv-cache-1`
- **StorageClasses:** `nvme-sc`
- **Nodes:** Worker nodes have a specific taint applied.

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n data-ops`

NAME          READY   STATUS    RESTARTS   AGE
web-cache-0   1/1     Running   0          5m22s
web-cache-1   0/1     Pending   0          2m14s

Command: kubectl get pvc -n data-ops

Plaintext
NAME               STATUS    VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   AGE
data-web-cache-0   Bound     pv-cache-0   1Gi        RWO            nvme-sc        5m23s
data-web-cache-1   Pending                                          nvme-stor      2m14s
Command: kubectl describe pod web-cache-1 -n data-ops

Plaintext
...
Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  2m10s  default-scheduler  0/2 nodes are available: 1 node(s) had untolerated taint {tier: cache}, 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }.
  Warning  FailedScheduling  60s    default-scheduler  0/2 nodes are available: 1 node(s) had untolerated taint {tier: cache}, 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }.
7. Difficulty
10/10

8. Skills Tested
StatefulSets & VolumeClaimTemplates

PersistentVolumes (PV) & PersistentVolumeClaims (PVC)

StorageClasses

Taints & Tolerations

Immutable Field Workarounds (--cascade=orphan)

Advanced Troubleshooting

9. Constraints
Do NOT delete the web-cache-0 pod. It must remain running continuously.

Do NOT delete or modify the existing PVs (pv-cache-0, pv-cache-1).

Do NOT delete the data-web-cache-0 PVC or lose its data.

Do NOT remove the tier=cache:NoSchedule taint from the worker nodes.