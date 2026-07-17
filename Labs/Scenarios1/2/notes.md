statefulset: 

pod is in peniding state
k describe pod -n data-ops
- pod has unound immediate pvc 
 (matching pvc not found)
- k get pvc -n data-ops 
- k dscribe pvc -n data-ops <pvc_name>
  storage class was wrong.
-
when you make statefull sets, you need to have different volumes for each pod, so you include the persistent volume claim template inside the statefulstate itself, so whatever pods are being made gets their own storage.

since spec section is immutable for the change of the storage class name, we cant directly change it.
there is way for it.
cascade orphan 
you take the yaml of the statefulset and delete the statefull set with command
k delete statefullset --cascade=orphan
when you do the cascade the already runing pod are not a part of teh statefull set anymore.
this will delete the statefulset adn not hte pods which were already created, 
now you delete hte pvc and the pod, and them edit the statefull set yaml and apply the changes]

We give a PersistentVolumeClaim to a StatefulSet so each Pod gets its own persistent storage that survives restarts, rescheduling, and scaling events. That is the main reason StatefulSets are used for databases and similar stateful apps
StatefulSets are designed for workloads that need:

stable Pod identity.

ordered creation and termination.

persistent, per-replica storage

When a StatefulSet creates a new Pod, Kubernetes can automatically create the matching PVC from the template. If the Pod restarts or gets recreated, it can reattach the same volume, so the data stays intact.


if you delete hte pvc it will come back again due to the volumetemplate inside the statefullset
if you delete the pod , it too will come again
you cant change the storage name in the statefullset simply as it is immutable.
only way seems to be recreate hte statefull set, but there is a way called cascading, with this you can delete the statefullset by keeping the running pod alive.
this works as follows
you take the yaml of the statefull set and save it.
delete the statefullset like this: k delete statefullset <name> --cascade=orphan
now delete the pod and the pvc affected one.
apply the yaml with the chnages and this statefullset will accept the orphaned pod0 which was running and will also solve hte proble.
in statefullset updates happens from top to bottom, example pod 2--> pod1 --->pod1 because k8s assume hte pod0 is the most important one.

there was a question that why you delete the pod1 before applying the statefullset again, so in statefull if a running healthy pod is there , it can remove that and keep your new pod, 
but if the existing pod wasnt scheduled or had problems, then it wont do the change simply

When you used --cascade=orphan, you deleted the manager (the StatefulSet), but you left pod-0 and pod-1 physically sitting in the cluster. Even though pod-1 was stuck in a Pending state and broken, it still existed as an object in Kubernetes.

When you applied your new, fixed YAML, here is what happened behind the scenes:

Adoption: The new StatefulSet controller woke up, looked at the cluster, and saw a pod named pod-1 that matched its label selectors. It immediately said, "Oh, this pod belongs to me," and adopted it.

The Stale Spec: Even though the StatefulSet had the new YAML (with the correct storage class and the new tolerations), the adopted pod-1 was still wearing its old configuration. Its individual pod definition had not changed.

The Freeze: Normally, a StatefulSet would trigger a Rolling Update to fix this mismatch. But remember the golden rule of StatefulSets: they refuse to do anything if a pod is not Ready. Because pod-1 was stuck in Pending, the controller just stared at it, completely paralyzed, waiting for it to become healthy before it would attempt to update it.