# Allocatable vs Allocated Resources

When Kubernetes schedules Pods on a Node, it uses the Node's **allocatable resources** rather than its total capacity.

### Basic idea

```text id="h0v0j6"
Allocatable Resources
        ↓
  - Allocated Resources
        ↓
Remaining Resources
        ↓
Available for new Pods
```

For example:

```text id="gq1b5c"
Node Allocatable CPU = 8 cores

Already allocated = 5 cores

Remaining = 8 - 5
         = 3 cores
```

So Kubernetes can schedule new Pods using the remaining **3 CPU cores**, assuming their resource requests can fit.

The same concept applies to **memory** and other schedulable resources.

### Remember

```text id="d5r8sy"
Total Node Capacity
        ↓
Kubernetes reserves some resources
        ↓
Allocatable Resources
        ↓
Subtract Pod resource requests
        ↓
Remaining capacity for new Pods
```

> **Important:** For scheduling, "allocated" generally refers to the resources requested by Pods, not necessarily the resources they are actually consuming at that moment.
