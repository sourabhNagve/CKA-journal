# 1. Exam Scenario

Task:
You have been paged for a severity-1 incident: The Kubernetes API Server is completely unresponsive, and administrators are receiving "connection refused" errors when using `kubectl`. 

Prior to the outage, a colleague was attempting to deploy an infrastructure-level logging agent (`fluentd-logger` DaemonSet) across all nodes in the cluster.

Troubleshoot and resolve the issues sequentially:
1. Identify and fix the cluster-level failure preventing the `kube-apiserver` from running.
2. Once the API server is restored, ensure the `fluentd-logger` DaemonSet successfully schedules on ALL nodes, including the control-plane node.
3. The `fluentd-logger` pods are crashing due to a storage configuration error. Fix the deployment so the pods reach the `Running` state.

When fully operational:
1. `kubectl` commands must execute successfully.
2. The `fluentd-logger` DaemonSet must have a pod `Running` on every node in the cluster (including the control plane).
3. The pod logs should output `Log collection started successfully.`

# 2. Initial Cluster State

- **Namespaces:** `observability`
- **DaemonSets:** `fluentd-logger` (in `observability`)
- **Control Plane State:** Unresponsive (`kube-apiserver` is crash-looping)

# 6. Expected kubectl Outputs

**Command:** `kubectl get nodes`
```text
The connection to the server <cluster-ip>:6443 was refused - did you specify the right host or port?

(Note: Because kubectl is broken, you must use node-level Linux commands like cat, crictl, or journalctl to investigate the static pods in /etc/kubernetes/manifests/.)

(Once the API server is fixed, you will see the following):
Command: kubectl get pods -n observability -o wide

Plaintext
NAME                   READY   STATUS             RESTARTS      AGE   NODE
fluentd-logger-abcde   0/1     CrashLoopBackOff   3 (14s ago)   5m    worker-node-1
(Notice no pod is scheduled on the control-plane node).

7. Difficulty
10/10

8. Skills Tested
API Server Troubleshooting (kube-apiserver.yaml static pod configuration)

Node-level debugging without kubectl (interacting with /etc/kubernetes/manifests)

DaemonSets and Tolerations (Allowing workloads on tainted control-plane nodes)

HostPath Volume Mounts

9. Constraints
This lab MUST be executed on a kubeadm provisioned control-plane node. You need root / sudo access.

Do NOT recreate the kube-apiserver.yaml file from scratch; find the syntax error introduced by your colleague and correct it.

Modify the fluentd-logger DaemonSet to tolerate the standard control-plane taint (node-role.kubernetes.io/control-plane:NoSchedule or master:NoSchedule).

Fix the hostPath volume in the DaemonSet so it points to the correct node-level logging directory (/var/log/containers), not the typoed directory.

10. Time Estimate
20 - 25 minutes