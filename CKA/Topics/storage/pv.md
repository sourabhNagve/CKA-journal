# Persistent Volumes: Node Affinity, Binding & Reclaim Policy

## PV Node Affinity

If you want a PersistentVolume to be available only from a **specific node**, add `nodeAffinity` to the PV.

Example:

```yaml id="i9w8wl"
nodeAffinity:
  required:
    nodeSelectorTerms:
      - matchExpressions:
          - key: kubernetes.io/hostname
            operator: In
            values:
              - node01
```

This means the PV is associated with:

```text id="1v7h0t"
node01
```

The Pod using the PVC must therefore be scheduled where the volume can be used.

---

# `volumeName` in PVC

Usually, you **do not need** to specify `volumeName` in a PVC.

Kubernetes automatically finds a matching PV based on things such as:

* Storage class
* Storage size
* Access modes
* Other matching requirements

### Normal case

```yaml id="em5p4q"
kind: PersistentVolumeClaim
```

Leave `volumeName` out and let Kubernetes handle the binding.

This keeps PVCs more portable and works well with dynamic provisioning.

### Manual / Explicit Binding

If you want a PVC to bind to one **specific PV**, specify:

```yaml id="8pvf1s"
spec:
  volumeName: my-pv
```

This is useful when you already know which PV or existing storage you want to use.

```text id="5vjsuh"
PVC
 │
 ├── volumeName: my-pv
 │
 ▼
Specific PV
```

---

# PVC Storage Is Mutable

The requested storage size of a PVC can be increased if the StorageClass and underlying storage support expansion.

For example:

```bash id="w1l4dv"
kubectl edit pvc my-pvc
```

Then increase:

```yaml id="f5y4b7"
resources:
  requests:
    storage: 20Gi
```

> PVC storage can generally be **increased**, but shrinking an existing PVC is not supported.

---

# PVC Binding Mode

The common default binding mode is:

```text id="h8i0kr"
Immediate
```

With `Immediate`, the PVC is provisioned/bound as soon as possible.

Another important mode is:

```text id="d2o4bq"
WaitForFirstConsumer
```

This delays provisioning/binding until a Pod using the PVC is created, which can help Kubernetes choose storage that is compatible with the Pod's scheduling constraints.

---

# PV Reclaim Policy

The PV's `persistentVolumeReclaimPolicy` determines what happens to the PV/storage after its PVC is deleted.

Common policies are:

```text id="mb75sq"
Retain
Delete
```

`Recycle` is deprecated and should generally not be used.

---

## `Retain`

If the PVC is deleted:

```text id="o4m0uj"
PVC deleted
    ↓
PV → Released
    ↓
Data remains
```

The PV is **not automatically made available to another PVC**.

It still contains the old PVC's `claimRef`.

To reuse it, an administrator generally needs to remove/clear the old claim reference and handle the existing data appropriately.

---

## `Delete`

If the PVC is deleted:

```text id="i0e1jh"
PVC deleted
    ↓
PV/storage is deleted
```

The exact cleanup behavior depends on the storage provisioner.

---

# Example Lifecycle with `Retain`

```text id="8k9n2v"
Deployment deleted
      ↓
Pod terminates
      ↓
Volume unmounted
      ↓
PVC still exists
      ↓
PVC deleted
      ↓
PV → Released
      ↓
Data remains intact
      ↓
Admin must handle the PV/data
```

With `Retain`, deleting the PVC **does not mean the underlying data is automatically deleted**.

---

# PVC / PV Protection

Kubernetes has protection mechanisms to reduce accidental deletion of storage resources that are still in use.

For example:

```text id="qyrqfs"
Pod
 ↓
PVC
 ↓
PV
 ↓
Storage
```

The Pod uses the PVC, and the PVC is bound to the PV.

Kubernetes can delay deletion of in-use resources until they are no longer being used.

### Important

You normally don't need to manually delete resources in a particular order just to make Kubernetes work. The protection mechanisms help prevent accidental data loss.

---

# Quick Mental Model

```text id="5zn6xy"
PV
 │
 ├── nodeAffinity → Where the PV can be used
 │
 └── reclaimPolicy → What happens after PVC deletion


PVC
 │
 ├── volumeName → Optional: force a specific PV
 │
 └── storage request → How much storage is requested
```

### Remember

```text id="g2d3pn"
No volumeName
    ↓
Kubernetes finds a matching PV


volumeName: my-pv
    ↓
Bind to a specific PV


Retain
    ↓
PVC deleted → PV Released → Data remains


Delete
    ↓
PVC deleted → Storage cleanup handled by provisioner
```
