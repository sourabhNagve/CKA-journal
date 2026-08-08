in a kube-proxy replacement setup,cilium can do the service routing work that kube-proxy normally does.
what that means:
- kube-proxy normally programs iptables or IPVS rules to send traffic to the right pods
- cilium can replace that with eBPF-based load balancing in the kernel, so clusterIP NodePort and the loadbalancer trafiic still works without kube-proxy

Note* cilium does not only copy kube-proxy; it replaces the service-routing part and also adds its own networking ,policy and observability features.

you can use cilium as cni and kubeproxy for routing by disabling the kubeproxy replacement