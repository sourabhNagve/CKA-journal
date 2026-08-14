# 1. Exam Scenario

Task:
A Junior Administrator was tasked with configuring an `audit-logger` static pod on the control-plane node and modifying the scheduling algorithm parameters. 

Since their intervention, the cluster's control plane is severely degraded:
1. New pods are stuck in the `Pending` state and are no longer being scheduled to worker nodes.
2. The `audit-logger` static pod they attempted to deploy is not functioning.

Log into the control-plane node to troubleshoot and resolve the system-level failures.

When fully operational:
1. The cluster's `kube-scheduler` must be `Running` and successfully scheduling new workloads.
2. The `audit-logger` static pod must be running successfully on the control-plane node.
3. The existing deployment `web-front` in the `default` namespace must reach 2/2 `Ready` replicas.

# 2. Initial Cluster State

- **Namespaces:** `kube-system`, `default`
- **Deployments:** `web-front` (in `default`, currently `Pending`)
- **Static Pods:** `kube-scheduler`, `audit-logger` (Targeted for control-plane)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n default`
```text
NAME                         READY   STATUS    RESTARTS   AGE
web-front-7b9c9d5d9b-abcde   0/1     Pending   0          4m
web-front-7b9c9d5d9b-vwxyz   0/1     Pending   0          4m

Command: kubectl get pods -n kube-system | grep scheduler

Plaintext
kube-scheduler-controlplane       0/1     CrashLoopBackOff   4          4m
(Note: Depending on the container runtime's restart backoff, the scheduler may also completely disappear from the list or show Error).

Command: crictl ps -a | grep audit-logger (Run on control-plane node)

Plaintext
<No output> or Exited with errors due to image pull failure.
7. Difficulty
10/10

8. Skills Tested
Static Pod Configuration & Troubleshooting

Control Plane Components (kube-scheduler)

Node-level debugging (/etc/kubernetes/manifests)

Container Runtime debugging (crictl or journalctl)

9. Constraints
This lab MUST be executed on the control-plane node of a kubeadm-provisioned cluster.

Do NOT delete or completely overwrite the kube-scheduler.yaml file. You must find the syntax error or misconfiguration introduced by the junior admin and correct it.

The audit-logger static pod must remain a static pod (do not convert it to a Deployment/DaemonSet).

Do NOT modify the web-front Deployment; it will automatically fix itself once the control plane is healthy.

10. Time Estimate
20 - 25 minutes