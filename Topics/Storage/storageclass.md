StorageClass helps Kubernetes dynamically provision storage for PVCs, and the default StorageClass is there so PVCs without an explicit class can still get provisioned automatically.
it is clusterscoped.
pv is clusterscoped
pvc is namescoped.