Static pods:
static pods are special type of pod that are managed directly by the kubelet on specific node, rather than by the kubernetes api server.They are defined by manifest files stored in a directory watched by kubelet.
- pod name automatically gets node name appended.
- can't be deleted by kubectl delete.
- automatically recreated by kubelet if they fail.
- tied to specific node where the manifest exists.
--------------------------
cert-manager
it is a operator that manages tls certificates automatically, it extends kubernetes by adding several crds that allow you to define certificates issuers and other certificate related resources decalaratively.\

--recursive - means kubectl explain will show the nested fields inside a resource, not just the top-level field names. For example, kubectl explain certificate.spec --recursive shows the fields under spec and their subfields as well