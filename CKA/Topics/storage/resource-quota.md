# ResourceQuota

**ResourceQuota is namespace-scoped.**

A ResourceQuota sets a limit on how much a **namespace** can consume.

It can limit resources such as:

* CPU
* Memory
* Storage
* Number of Kubernetes objects

It prevents one application or team from consuming too many resources in a shared cluster.

### Why use ResourceQuota?

It helps keep the cluster:

* **Fair** — one namespace cannot consume everything.
* **Stable** — prevents excessive resource consumption.
* **Predictable** — teams have defined resource limits.

### Simple Mental Model

```text id="y3h9l7"
Cluster
  │
  ├── Namespace A
  │     └── ResourceQuota → limit
  │
  ├── Namespace B
  │     └── ResourceQuota → limit
  │
  └── Namespace C
        └── ResourceQuota → limit
```

> **Remember:** ResourceQuota limits the total resource consumption **within a namespace**. It does not directly control individual Pods; use resource requests/limits for that.
