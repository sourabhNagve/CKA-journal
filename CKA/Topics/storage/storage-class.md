# StorageClass

A **StorageClass** allows Kubernetes to **dynamically provision storage** for PersistentVolumeClaims (PVCs).

A **default StorageClass** allows PVCs that don't specify `storageClassName` to be automatically provisioned using the default class.

## Resource Scope

```text id="c1e2yx"
StorageClass → Cluster-scoped
PV           → Cluster-scoped
PVC          → Namespace-scoped
```

---

## What Does a StorageClass Do?

A StorageClass defines the different types of storage a cluster can offer and tells Kubernetes how to automatically create storage when a PVC requests it.

Without dynamic provisioning, you would generally need to manually create a PV before a PVC can use it.

```text id="p9h6t0"
PVC
 ↓
StorageClass
 ↓
Provisioner
 ↓
PV created automatically
 ↓
Storage
```

---

## What Does a StorageClass Define?

A StorageClass tells Kubernetes:

* **What type of storage** to create — SSD, HDD, cloud disk, etc.
* **Performance tier** — different storage performance levels
* **Who creates it** — the storage `provisioner`
* **What happens when the volume is deleted** — `reclaimPolicy`

### Simple Mental Model

```text id="2f4d1x"
StorageClass
      ↓
"How should storage be provisioned?"
      ↓
PVC requests storage
      ↓
Provisioner creates PV
      ↓
PV provides storage to the Pod
```

> **Remember:** StorageClass is the **template/rules for provisioning storage**, PV is the **actual storage resource**, and PVC is the **request for storage**.
