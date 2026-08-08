# 1. Exam Scenario

Task:
You are the administrator of a Kubernetes cluster. A critical scheduled maintenance window is approaching, and you must perform a full backup of the cluster's state. Following the backup, you must simulate a disaster recovery scenario by restoring the cluster from your snapshot.

Perform the following tasks on the control-plane node:
1. Take a snapshot of the running `etcd` database and save it to `/opt/backup/etcd-snapshot.db`. (You must authenticate using the correct PKI certificates located in `/etc/kubernetes/pki/etcd/`).
2. Restore the snapshot to a completely new data directory: `/var/lib/etcd-restored`.
3. Reconfigure the cluster to use this new restored data directory instead of the original `/var/lib/etcd` directory.

When fully operational:
1. The `etcd-snapshot.db` file must exist at the specified path.
2. The `etcd` static pod must be running and successfully utilizing `/var/lib/etcd-restored` as its data volume.
3. The cluster must be fully responsive to `kubectl` commands after the restoration.

# 2. Initial Cluster State

- **ETCD PKI Directory:** `/etc/kubernetes/pki/etcd/`
- **Current ETCD Data Dir:** `/var/lib/etcd`
- **Target Backup File:** `/opt/backup/etcd-snapshot.db`
- **Target Restore Dir:** `/var/lib/etcd-restored`

# 6. Expected kubectl Outputs

*(After you update the etcd configuration, the API server will temporarily drop connections as etcd restarts. Wait 30-60 seconds).*

**Command:** `kubectl get pods -n kube-system -l component=etcd`
```text
NAME                     READY   STATUS    RESTARTS   AGE
etcd-controlplane-node   1/1     Running   0          1m

Command: grep "path: /var/lib/etcd" /etc/kubernetes/manifests/etcd.yaml

Plaintext
      path: /var/lib/etcd-restored
7. Difficulty
10/10

8. Skills Tested
ETCD Backup and Restore (etcdctl snapshot save, etcdctl snapshot restore)

Static Pod Manipulation (/etc/kubernetes/manifests/etcd.yaml)

Control Plane Component Lifecycles

9. Constraints
This lab MUST be executed on a kubeadm provisioned control-plane node with etcdctl installed. You need root / sudo access.

Do NOT stop the kubelet service or manually kill the etcd container; modifying the static pod manifest automatically restarts etcd.

Do NOT overwrite the original /var/lib/etcd directory. You must point the configuration to the newly created /var/lib/etcd-restored directory.

10. Time Estimate
15 - 20 minutes