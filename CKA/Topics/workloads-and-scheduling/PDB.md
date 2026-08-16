# Pod Disruption Budget (PDB)

A **Pod Disruption Budget (PDB)** tells Kubernetes how many Pods of an application should remain available during **voluntary disruptions**, such as:

* Node draining
* Cluster upgrades
* Planned maintenance

It helps prevent too many replicas of an application from being evicted at the same time.

---

## What It Does

* Protects application availability during planned disruptions.
* Can define either:

  * `minAvailable` → minimum number of Pods that must remain available.
  * `maxUnavailable` → maximum number of Pods that can be unavailable.
* Is respected by the Kubernetes **eviction flow**, so Kubernetes checks the PDB before allowing a voluntary Pod eviction.

---

## Example

Suppose an application has:

```yaml
replicas: 5
```

You can create a PDB with:

```yaml
minAvailable: 4
```

This means Kubernetes should keep at least **4 Pods available** during voluntary disruptions.

Or:

```yaml
maxUnavailable: 1
```

This means at most **1 Pod** can be unavailable due to voluntary disruption.

```text
5 replicas
   │
   ├── Pod 1  ✅
   ├── Pod 2  ✅
   ├── Pod 3  ✅
   ├── Pod 4  ✅
   └── Pod 5  ❌ ← can be disrupted

Minimum available = 4
```

---

## When It Matters

PDBs are especially useful:

* During **maintenance or cluster upgrades**
* For applications with **multiple replicas** that should not go down together
* For critical APIs, queues, and other highly available workloads
* In **production environments** where availability is more important than fast eviction

### Simple Mental Model

```text
Without PDB:
Node drain
   ↓
Multiple Pods may be evicted
   ↓
Application availability may suffer


With PDB:
Node drain
   ↓
Kubernetes checks PDB
   ↓
Only allowed number of Pods are disrupted
   ↓
Application stays available
```

> **Remember:** PDBs protect against **voluntary disruptions**. They do not prevent a Pod from going down because of crashes, hardware failures, or other involuntary disruptions.
