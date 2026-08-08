The Kubernetes NetworkPolicy Trap: Service Port vs. Target Port

Have you ever allowed a port in a Kubernetes NetworkPolicy, only to watch your connection mysteriously timeout?
You likely fell into a common trap, caused by a misunderstanding of how Kubernetes routes internal traffic.
When your pod calls a virtual Service (like kubernetes.default.svc:443), kube-proxy intercepts the packet.
It immediately translates that destination to the physical Pod Endpoint, rewriting the port from 443 to the actual targetPort (6443).
Here is the catch: your network plugin (CNI) evaluates Egress policies after this translation happens!
If your policy only allowed 443, the CNI sees a packet now destined for 6443 and silently drops it.
We rarely notice this because 95% of the time, the Service port and targetPort are identical (like port 80 to targetPort 80).
But when those numbers differ—like a masked database or the K8s API—your seemingly perfect policy will block traffic.
The Golden Rule: NetworkPolicies do not understand Services; they only see physical endpoints.
To fix your blocked traffic, always allow the targetPort in your rules, never the Service port.