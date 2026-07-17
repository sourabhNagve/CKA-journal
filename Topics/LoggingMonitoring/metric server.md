The Metrics Server is a lightweight Kubernetes component that collects CPU and memory usage from nodes and pods and exposes that data through the Kubernetes Metrics API. It is mainly used by HPA and similar autoscaling features to make scaling decisions.
What it gives
Current CPU and memory usage for nodes and pods.

Data for autoscaling, not long-term monitoring history.

Commands:
kubectl top nodes
kubectl top pods.


What it does not do:- 
It does not store historical metrics.
It is not a full monitoring system like Prometheus.