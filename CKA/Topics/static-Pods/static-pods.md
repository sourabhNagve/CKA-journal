# Static Pods

**Static Pods** are managed directly by the **kubelet on a specific node**, rather than by the Kubernetes API server.

They are defined using Pod manifest files stored in a directory that the kubelet watches.

```text id="z0eqbd"
Manifest file
     ↓
Kubelet watches directory
     ↓
Kubelet creates Pod
     ↓
Pod runs on that specific node
```

## Key Points

* Static Pods are tied to the **specific node** where their manifest exists.
* The kubelet automatically creates and manages them.
* If a Static Pod fails, the kubelet can recreate it.
* You cannot directly manage the Static Pod through the Kubernetes API like a normal Pod.
* The Pod name usually gets the **node name appended**.

For example:

```text id="b2h7wq"
nginx-node01
```

---

## Mirror Pods

When a Static Pod is running, the kubelet creates a **mirror Pod** in the Kubernetes API server.

This allows you to see the Static Pod with:

```bash id="2h4j9s"
kubectl get pods
```

However, the mirror Pod is only a representation of the Static Pod.

```text id="m5yn8k"
Static Pod
    │
    │ managed by
    ▼
  Kubelet
    │
    │ creates mirror
    ▼
Mirror Pod
    │
    ▼
API Server
```

If you try:

```bash id="9l6g2w"
kubectl delete pod <static-pod>
```

you cannot actually remove the underlying Static Pod because the kubelet will continue managing it from its manifest.

To remove the Static Pod, you need to remove or modify its **manifest file** on the node.

### Remember

```text id="v4x9kp"
Normal Pod:
API Server → Scheduler → Kubelet → Pod

Static Pod:
Manifest → Kubelet → Pod
                    ↓
               Mirror Pod
                    ↓
                API Server
```

> **Static Pod = kubelet-managed Pod defined by a local manifest.**
