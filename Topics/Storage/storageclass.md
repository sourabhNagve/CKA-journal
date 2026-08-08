StorageClass helps Kubernetes dynamically provision storage for PVCs, and the default StorageClass is there so PVCs without an explicit class can still get provisioned automatically.
it is clusterscoped.
pv is clusterscoped
pvc is namescoped.



---------------
Storage class defines different types of storage cluster offers,to automatically create volumes when needed
without this you have to manually create pv and provision the volume
storage class template tells:
- kind of storage it creates(ssd,hdd, cloud disk etc)
- how fast it should be (performance tiers)
- who creates it (the provisioner)
- what happens when deleted(reclaim policy) 