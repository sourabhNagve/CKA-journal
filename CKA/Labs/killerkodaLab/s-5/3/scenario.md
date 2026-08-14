# 1. Exam Scenario

Task:
A critical application pipeline requires extremely precise placement on the cluster. You must configure manual scheduling, self-healing probes, and complex affinity rules in the `pipeline-ns` namespace.

Perform the following tasks sequentially:

1. **Manual Scheduling & Probes:** The `kube-scheduler` cannot be trusted with the legacy workload. Create a pod named `legacy-worker` using the `nginx:alpine` image.
   - **Bypass the Scheduler:** Bind the pod directly to the cluster's primary node (the one you are currently on) using the `nodeName` field. (Do NOT use `nodeSelector`).
   - **Liveness Probe:** Configure an `exec` liveness probe that runs the command `cat /usr/share/nginx/html/index.html`.
   - **Readiness Probe:** Configure an `httpGet` readiness probe that checks the `/` path on port `80`.

2. **Advanced Affinity:** Create a Deployment named `smart-cache` using the `redis:alpine` image with `2` replicas.
   - **Node Affinity:** The pods MUST strictly schedule only on nodes containing the label `tier=frontend` (Use `requiredDuringSchedulingIgnoredDuringExecution`).
   - **Pod Anti-Affinity:** To ensure high availability, no two `smart-cache` pods can ever run on the same node. Configure strict pod anti-affinity targeting the label `app=smart-cache` with the topology key `kubernetes.io/hostname` (Use `requiredDuringSchedulingIgnoredDuringExecution`).

When fully operational:
1. The `legacy-worker` pod must be running and show `1/1` READY (indicating the probes passed).
2. The `smart-cache` deployment must have at least one pod running. *(Note: If you are practicing on a single-node cluster, the second replica will remain `Pending` — this proves your Anti-Affinity rule worked perfectly).*

# 2. Initial Cluster State

- **Namespaces:** `pipeline-ns`
- **Node Labels:** The active node has been labeled with `tier=frontend`.

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n pipeline-ns`
```text
NAME                           READY   STATUS    RESTARTS   AGE
legacy-worker                  1/1     Running   0          2m
smart-cache-5c77b5b48b-abcde   1/1     Running   0          2m
smart-cache-5c77b5b48b-fghij   0/1     Pending   0          2m  <-- (If single node)

7. Difficulty
9/10

8. Skills Tested
Bypassing the scheduler (nodeName)

Liveness & Readiness Probes (exec and httpGet)

Node Affinity (Required)

Pod Anti-Affinity (Required)

9. Constraints
Do NOT use nodeSelector for the legacy-worker; you must use nodeName to demonstrate scheduler bypass.

The smart-cache pods must have the label app=smart-cache for the anti-affinity rule to function.

You will have to write the Affinity rules from scratch or adapt them heavily from the Kubernetes documentation. Pay close attention to your YAML arrays (hyphens).

10. Time Estimate
15 - 20 minutes