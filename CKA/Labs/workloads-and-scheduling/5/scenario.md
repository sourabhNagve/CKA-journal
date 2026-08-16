A Kafka StatefulSet (kafka) in the messaging namespace is running out of disk space. The PersistentVolumes backing it currently hold critical state, but their Reclaim Policy is dangerously set to Delete. Furthermore, clients are unable to reliably discover the Kafka pods because the associated Service was incorrectly created as a standard ClusterIP service instead of a Headless service. Note: You cannot directly edit a StatefulSet's volumeClaimTemplates field once created.

Your Tasks:

Fix Service Discovery (Headless): Modify the kafka-svc Service in the messaging namespace. It must be converted into a true Headless Service (clusterIP: None) so stable DNS records are generated for each StatefulSet pod.

Prevent Data Loss: Patch the two PersistentVolumes backing this StatefulSet (pv-kafka-0 and pv-kafka-1) to change their persistentVolumeReclaimPolicy from Delete to Retain.

Expand Storage In-Place: Increase the storage capacity of the two corresponding PersistentVolumeClaims (data-kafka-0 and data-kafka-1) in the messaging namespace from 1Gi to 3Gi. (You must edit the PVCs directly).