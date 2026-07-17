# 1. Exam Scenario

Task:
A deployment named `data-aggregator` in the `analytics` namespace is designed to continuously fetch metrics from an internal API service (`data-api`) located in the `internal-services` namespace.

Currently, the `data-aggregator` application is completely failing. 

Troubleshoot and resolve all issues in the sequence they appear. 

When fully operational:
1. The `analytics-pvc` must successfully bind to the existing PersistentVolume.
2. The `data-aggregator` pods must reach the `Running` state without shadowing critical OS directories.
3. The `data-aggregator` pod must successfully communicate with the `data-api` service and log `SUCCESS`.

# 2. Initial Cluster State

- **Namespaces:** `analytics`, `internal-services`
- **Deployments:** `data-aggregator` (in `analytics`), `data-api` (in `internal-services`)
- **Services:** `data-api` (in `internal-services`)
- **PVs:** `analytics-pv`
- **PVCs:** `analytics-pvc` (in `analytics`, currently `Pending`)
- **NetworkPolicies:** `restrict-api-access` (in `internal-services`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pvc -n analytics`
```text
NAME            STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
analytics-pvc   Pending                                      manual         2m.


Command: kubectl describe pvc analytics-pvc -n analytics

Plaintext
...
Events:
  Type     Reason         Age               From                         Message
  ----     ------         ----              ----                         -------
  Warning  FailedBinding  12s (x5 over 2m)  persistentvolume-controller  volume "analytics-pv" already bound to a different claim. (or) no persistent volumes available for this claim and no storage class is set
(Note: Once you fix the storage binding issue, the pod will schedule but its logs will show DNS resolution failures. Once you fix the DNS/Mount issue, it will show network timeouts until the final fix is applied).

Command: kubectl logs -n analytics deploy/data-aggregator

Plaintext
wget: bad address 'data-api.internal-services.svc.cluster.local'
FAIL
wget: bad address 'data-api.internal-services.svc.cluster.local'
FAIL
7. Difficulty
9.5/10

8. Skills Tested
Persistent Volumes (Capacity Mismatches)

PVC lifecycle (Deleting/Recreating claims)

Volume Mount Paths & OS-level Directory Shadowing (/etc)

Cross-Namespace NetworkPolicies & Namespace Labeling

9. Constraints
Do NOT modify or delete the analytics-pv PersistentVolume.

You MAY delete and recreate the analytics-pvc PersistentVolumeClaim, but it must retain the same name and bind to analytics-pv.

Do NOT modify any resources in the internal-services namespace.

You MUST modify the environment to satisfy the existing restrict-api-access NetworkPolicy.

The data-aggregator deployment must retain its volume mount, but you must change its mountPath to /data so it does not destroy container DNS.

10. Time Estimate
15 - 25 minutes