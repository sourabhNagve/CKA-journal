kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl edit deployment metrics-server -n kube-system
put these
- --kubelet-insecure-tls
- --kubelet-preferred-address-types=InternalIP

inside below
     containers:
     - args:
       - --cert-dir=/tmp
       - --secure-port=10250
       - --kubelet-preferred-address-types=InternalIP
       - --kubelet-use-node-status-port
       - --metric-resolution=15s
       - --kubelet-insecure-tls
       image: registry.k8s.io/metrics-server/metrics-server:v0.7.1
by default kubeadm utilises the self signed certificates for node kubelets., the metric server will throw a readiness probe error because it cannot verify these certs by default.
