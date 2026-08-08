
 - Run kubectl describe pod <name> first — the Events section reveals mostof issues. Then kubectl logs <name> --previous if the container crashed
- If the node is not in ready state, then ssh to the node and systemctl status kubelet, if stopped, run systemctl restart kubelet. Then journalctl -u kubelet (common causes disk pressure df-h or memory pressure free -m or expired certificates)
---------CRASHLOOPBACKOFF------
Reasons a pod goes into the crashloopbackoff are:
- the apps insise the container crashed on startup
- wrong command,entry point, or arguments are configured.
- missing or bad env variables,cm or secrets.
- the image is wrong or missing or cannot be pulled
- cpu memory limits are too low, causing the container to be killed including OOM killed.
- liveness or startup probes are too aggresive or misconfigured.
- init containers fail before the main container can run.
- the app depend of another service that is not yet ewady, such as database.

k describe pod <podname>
k logs <podname> and k logs <podname> --previous ( to see the crash output from the last run)
resorse limits and probe settings in the pod or deployment spec.

--------PENDING--------
If the pod is in pending state that means it is not scheduled on any node yet
- Not enough cpu or memory on any node to satisfy the pods request.
- nodeselector ,nodeaffinity, or topology rules do not match any node.
- taints on nodes are blocking the pod because it lacks matching tolerations.
- a pvc is still pending or storage cannot be bound.
- the node is cordoned or otherwise unschedulable.
- the cluster autoscaler is not adding nodes fast or cannot scale.

first checks.
k describe pod <podname>
k get pvc
k get pv
k get nodes
k describe node <nodename>
------------------------------------------

Symptom → Cause → Fix (Quick Reference)
Symptom	Most Likely Cause	First Fix
Node NotReady	kubelet stopped	systemctl start kubelet
Pod CrashLoopBackOff	App error or bad config	kubectl logs <pod> --previous
Pod OOMKilled	Memory limit too low	Increase resources.limits.memory
Pod ImagePullBackOff	Wrong image name/tag	kubectl describe pod → fix image
Pod Pending	No schedulable node	Check taints, affinity, resources
Service no endpoints	Label selector mismatch	Fix spec.selector in service
DNS not resolving	CoreDNS down	kubectl get pods -n kube-system -l k8s-app=kube-dns
PVC Pending	No matching PV or StorageClass (*)	kubectl describe pvc → check StorageClass
Scheduler not running	Bad static pod manifest	Fix /etc/kubernetes/manifests/kube-scheduler.yaml


kubectl get events -n <ns> --sort-by='.lastTimestamp'


netstat -tlnp

----------
OOM kills: memory limits too low
CPU Throttling: limits too restrictive
failed scheduling: requests exceeds node capacity.
Node pressure: too many pods consuming resources.
