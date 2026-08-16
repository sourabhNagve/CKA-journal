# Pod Anti-Affinity & Topology Spread Constraints

## Pod Anti-Affinity

**Pod anti-affinity** is useful when you want Pods to avoid being scheduled near other Pods, which can help with **high availability (HA)**.

For example, you may want replicas of the same application to run on different nodes or zones.

There are two types:

* `requiredDuringSchedulingIgnoredDuringExecution` → **Hard requirement**
* `preferredDuringSchedulingIgnoredDuringExecution` → **Preference**

You can also choose the topology domain:

* `hostname` → spread across nodes
* `zone` → spread across availability zones
* `region` → spread across regions

---

## Required vs Preferred

### `requiredDuringSchedulingIgnoredDuringExecution`

A **hard requirement**.

The Pod must satisfy the rule to be scheduled.

If no suitable node exists, the Pod remains **Pending**.

Think:

```text
Rule must be satisfied
        ↓
If not → Pod stays Pending
```

It is similar to `nodeSelector`, but more expressive because anti-affinity can use relationships between Pods.

---

### `preferredDuringSchedulingIgnoredDuringExecution`

A **preference**.

The scheduler tries to satisfy the rule, but if it cannot, the Pod can still be scheduled elsewhere.

Think:

```text
Try to satisfy rule
        ↓
If possible → use it
If not      → schedule elsewhere
```

`weight` affects how strongly the scheduler prefers that rule during scoring.

> **Important:** `weight: 50` does not guarantee even Pod distribution. If your goal is to evenly distribute replicas, use `topologySpreadConstraints`.

---

# Topology Spread Constraints

`topologySpreadConstraints` are used to **spread Pods evenly across topology domains** such as:

* Nodes
* Zones
* Regions

They are especially useful for highly available applications.

### Without Topology Spread

```text
Scheduler
    ↓
Node A: 7 Pods ❌
Node B: 0 Pods
```

All replicas are on one node, creating a potential single point of failure.

### With Topology Spread

For 7 replicas across 2 domains with:

```yaml
maxSkew: 1
```

a valid distribution could be:

```text
Domain A: 4 Pods
Domain B: 3 Pods

Difference = 1 ✅
```

Other valid distribution:

```text
Domain A: 3 Pods
Domain B: 4 Pods

Difference = 1 ✅
```

But:

```text
Domain A: 5 Pods
Domain B: 2 Pods

Difference = 3 ❌
```

---

## `maxSkew`

`maxSkew` defines how much the number of Pods can differ between topology domains.

For example:

```yaml
maxSkew: 1
```

means the scheduler tries to keep the difference within **1 Pod**.

```text
4 vs 3 → ✅
5 vs 3 → ❌
```

---

## Simple Mental Model

```text
Pod Anti-Affinity
        ↓
"Don't place these Pods together"


Topology Spread Constraints
        ↓
"Keep these Pods evenly distributed"
```

Use **Pod anti-affinity** when you specifically want Pods to avoid each other.

Use **topology spread constraints** when the main goal is **controlled and even distribution of replicas** across nodes, zones, or other topology domains.
