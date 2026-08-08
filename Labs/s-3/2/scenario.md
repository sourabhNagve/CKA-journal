# 1. Exam Scenario

Task:
A catastrophic human error resulted in the accidental deletion of the `critical-data` namespace, which contained the `db-backend` deployment. 

Fortunately, an automated backup script took a snapshot of the `etcd` database just before the deletion occurred. The snapshot file is located on the control-plane node at `/opt/backup/etcd-snapshot.db`.

Restore the cluster state from this snapshot.

When fully operational:
1. The `etcd` cluster must be healthy and utilizing the restored data.
2. The `critical-data` namespace and its `db-backend` deployment must be present and fully accessible.
3. The cluster control plane must be stable.

# 2. Initial Cluster State

- **Namespaces:** `default`, `kube-system`
- **Missing Namespaces:** `critical-data` (Accidentally deleted)
- **Snapshot Location:** `/opt/backup/etcd-snapshot.db`
- **Control Plane Type:** Stacked `kubeadm` (etcd runs as a static pod)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n critical-data`
```text
No resources found in critical-data namespace.

(Before restore, the namespace does not exist or is terminating).

Command: kubectl get ns critical-data

Plaintext
Error from server (NotFound): namespaces "critical-data" not found
(After a successful restore, the namespace will reappear).
Command: kubectl get pods -n critical-data

Plaintext
NAME                          READY   STATUS    RESTARTS   AGE
db-backend-7c9b5d6b49-abcde   1/1     Running   0          15m
7. Difficulty
10/10

8. Skills Tested
etcd Backup and Restore procedures

etcdctl CLI usage and PKI authentication

Static Pod configuration (/etc/kubernetes/manifests/etcd.yaml)

Control Plane recovery and cluster component lifecycle

9. Constraints
This task MUST be executed on the control-plane node as root (or using sudo).

Do NOT overwrite the existing /var/lib/etcd directory. You must restore the snapshot to a new directory (e.g., /var/lib/etcd-backup) and modify the etcd.yaml manifest to point to this new location.

The etcdctl utility must authenticate using the existing PKI certificates located in /etc/kubernetes/pki/etcd/.

10. Time Estimate
15 - 20 minutes