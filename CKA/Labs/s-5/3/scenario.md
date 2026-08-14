# 1. Exam Scenario

Task:
You have been paged for a severity-1 outage on `cluster-alpha`. The cluster control plane is highly unstable, a worker node has dropped offline, and a junior admin accidentally deleted the `financial-core` namespace an hour ago. 

You must restore the cluster state, fix the control plane, recover the worker node, and extract data from the restored namespace.

**Perform the following tasks on the controlplane node:**
1. **Control Plane Repair:** The `kube-apiserver` is continuously crashing. Identify the misconfiguration in its static pod manifest located at `/etc/kubernetes/manifests/kube-apiserver.yaml` and fix it so the API server starts successfully.
2. **State Recovery (ETCD):** An ETCD snapshot was taken right before the namespace deletion. It is located at `/opt/backups/etcd-snapshot.db`. 
   - Restore this snapshot to a new data directory at `/var/lib/etcd-restored`.
   - Update the `etcd` static pod manifest to use this new data directory so the `financial-core` namespace is recovered.
   - *Certificates for etcdctl are located in `/etc/kubernetes/pki/etcd/`.*
3. **Node Recovery:** The node `worker-1` is in a `NotReady` state. SSH into `worker-1` (simulated), identify why the `kubelet` service is failing, fix the configuration file, and ensure the node transitions to `Ready`.
4. **Data Extraction:** Once the cluster is healthy and the `financial-core` namespace is restored, find all pods running in the `financial-core` namespace. Extract their container images using a JSONPath query and save the list to `/opt/financial-images.txt`.

When fully operational:
1. `kubectl get nodes` shows all nodes as `Ready`.
2. `kubectl get ns financial-core` succeeds.
3. `/opt/financial-images.txt` contains the image names.

# 2. Initial Cluster State

- **Nodes:** `controlplane` (Ready), `worker-1` (NotReady)
- **Namespaces:** `financial-core` (Deleted, exists only in the backup)

# 6. Expected kubectl Outputs

**Command:** `kubectl get nodes`
```text
NAME           STATUS   ROLES           AGE   VERSION
controlplane   Ready    control-plane   15d   v1.30.0
worker-1       Ready    <none>          15d   v1.30.0

Command: cat /opt/financial-images.txt

Plaintext
nginx:1.23.0 redis:7.0-alpine
7. Difficulty
10/10 (Killer.sh Level)

8. Skills Tested
Static Pod Manifest Troubleshooting

etcdctl Snapshot Restore process

systemd / journalctl kubelet debugging

JSONPath extraction

9. Constraints
Do NOT overwrite the existing /var/lib/etcd directory. You must restore to /var/lib/etcd-restored and point the ETCD pod to it.

You must use the correct etcdctl flags for the CA, cert, and key to authenticate.

10. Time Estimate
20 - 25 minutes