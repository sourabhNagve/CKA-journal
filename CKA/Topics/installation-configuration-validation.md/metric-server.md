# Metrics Server

Install Metrics Server:

    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

Edit the Metrics Server deployment:

    kubectl edit deployment metrics-server -n kube-system

Under `spec.containers[].args`, add:

    - --kubelet-insecure-tls
    - --kubelet-preferred-address-types=InternalIP

Example:

    containers:
    - args:
      - --cert-dir=/tmp
      - --secure-port=10250
      - --kubelet-preferred-address-types=InternalIP
      - --kubelet-use-node-status-port
      - --metric-resolution=15s
      - --kubelet-insecure-tls

### Why?

In kubeadm clusters, kubelets commonly use certificates that Metrics Server cannot verify by default.

- `--kubelet-insecure-tls` → skips kubelet certificate verification.
- `--kubelet-preferred-address-types=InternalIP` → tells Metrics Server to connect to kubelets using their InternalIP.

Without the required configuration, Metrics Server may fail its readiness checks and metrics may not be available.