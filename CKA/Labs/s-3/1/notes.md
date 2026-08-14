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