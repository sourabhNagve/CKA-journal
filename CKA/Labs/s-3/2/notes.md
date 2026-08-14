etcdutl snapshot restore --data-dir=/var/lib/ snapshot.db
mv the original etcd from /var/lib and change its name to etcd-old
now chnage the data-dir in teh yaml volume and volume mounts to new data dir,
chnage the name of the data dir of the new snapshot to etcd
