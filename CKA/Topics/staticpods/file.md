Static pods:
static pods are  managed directly by the kubelet on specific node, rather than by the kubernetes api server.
They are defined by manifest files stored in a directory watched by kubelet.
- pod name automatically gets node name appended.
- can't be deleted by kubectl delete.
- automatically recreated by kubelet if they fail.
- tied to specific node where the manifest exists.
- when you do "kubectl get pods" you will see these pods, when kubernetes see these static pod, it makes mirror of them, but they cant be deleted with kube-api