# 1. Exam Scenario

Task:
A critical application update was deployed to the `processing` namespace, but the entire environment has collapsed. 

The `data-processor` deployment is completely offline. Upon initial inspection, you will find a cascade of failures spanning cluster DNS, node scheduling constraints, persistent storage binding, and internal service routing. 

Troubleshoot and resolve the issues sequentially:
1. **Cluster DNS is down:** CoreDNS pods in the `kube-system` namespace are in a `CrashLoopBackOff` state due to a recent configuration change. Identify and remove the syntax error in the CoreDNS ConfigMap to restore cluster-wide DNS.
2. **Scheduling Failure:** The `data-processor` pod is stuck in `Pending`. A mandatory maintenance taint was applied to the node, preventing the pod from scheduling. Modify the `data-processor` deployment to tolerate this taint.
3. **Storage Failure:** Even after scheduling, the pod remains stuck. Its `PersistentVolumeClaim` is pending because it requests more capacity than the available `PersistentVolume` provides. Delete and recreate the PVC to correctly request exactly `2Gi` to match the provisioned PV.
4. **Network Routing Failure:** Once the pod is running, its logs indicate it cannot connect to the `redis-queue` service. Identify and fix the misconfiguration in the `redis-queue` Service so traffic routes correctly to the Redis pod.

When fully operational:
1. CoreDNS must be `Running`.
2. The `data-pvc` must be `Bound` to `data-pv`.
3. The `data-processor` pod must be `Running`.
4. The logs of the `data-processor` pod must output `Connected to Redis database successfully.`

# 2. Initial Cluster State

- **Namespaces:** `processing`
- **Deployments:** `data-processor`, `redis` (in `processing`)
- **Services:** `redis-queue` (in `processing`)
- **Storage:** `data-pv` (Cluster-scoped), `data-pvc` (in `processing`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n kube-system -l k8s-app=kube-dns`
```text
NAME                       READY   STATUS    RESTARTS   AGE
coredns-6d4b75cb6d-abcde   1/1     Running   0          5m

Command: kubectl logs deploy/data-processor -n processing | tail -n 1

Plaintext
Connected to Redis database successfully.
7. Difficulty
11/10 (Final Boss)

8. Skills Tested
CoreDNS ConfigMap Troubleshooting

Node Taints and Pod Tolerations

PV/PVC Capacity Binding (Recreating PVCs)

Service Label Selectors & Endpoints

9. Constraints
Do NOT remove the taint from the node. You must use a toleration on the deployment.

Do NOT modify the capacity of the data-pv PersistentVolume. Recreate the PVC to match it.

Modify the existing redis-queue Service to fix the selector; do not create a new service.

10. Time Estimate
25 - 30 minutes