# 1. Exam Scenario

Task:
The data science team has deployed a new persistent database pod named `db-app` in the `data-store` namespace. However, the pod has been stuck in the `Pending` state for the last hour.

Upon investigation, you will find that the PersistentVolumeClaim (PVC) it relies on is also `Pending`, failing to bind to the existing PersistentVolume (PV) provisioned by the storage admins.

Troubleshoot and resolve the storage stack issues:
1. Identify why the `data-pvc` is failing to bind to the `data-pv`. (Hint: Pay close attention to Access Modes).
2. Fix the PVC so that it successfully binds to the PV. You may need to recreate the PVC to modify immutable fields.
3. Once the PVC is bound, the `db-app` pod will still crash. Inspect the pod and fix the volume mounting configuration so it correctly mounts the volume to `/var/lib/mysql`.

When fully operational:
1. The PV `data-pv` and PVC `data-pvc` must both show a status of `Bound`.
2. The `db-app` pod must be in the `Running` state.
3. The database must be able to write its initialization files to the persistent volume.

# 2. Initial Cluster State

- **Namespaces:** `data-store`
- **PersistentVolumes (Cluster-scoped):** `data-pv`
- **PersistentVolumeClaims:** `data-pvc` (in `data-store`)
- **Pods:** `db-app` (in `data-store`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pv,pvc -n data-store`
```text
NAME                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
persistentvolume/data-pv   2Gi        RWO            Retain           Available           manual                  2m

NAME                             STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/data-pvc   Pending                                      manual         2m

Command: kubectl get pods -n data-store

Plaintext
NAME     READY   STATUS    RESTARTS   AGE
db-app   0/1     Pending   0          2m
7. Difficulty
8.5/10

8. Skills Tested
PersistentVolumes (PV) & PersistentVolumeClaims (PVC)

PV/PVC Binding Criteria (StorageClass, Capacity, AccessModes)

Pod VolumeMounts

Recreating immutable resources

9. Constraints
Do NOT delete or modify the data-pv PersistentVolume. The storage admins provisioned it exactly to spec.

You must delete and recreate the data-pvc PersistentVolumeClaim to fix its binding requirements. Maintain its name and requested capacity (2Gi).

Modify the db-app Pod to fix its volume mount. (Note: Pods cannot have their volume mounts modified in-place; you must extract the YAML, delete the pod, edit the YAML, and re-apply).

10. Time Estimate
15 - 20 minutes