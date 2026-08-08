ConfigMap is an api object to store non-confidential data in key-value pairs.
Pods can consume cm as env, command line arguments, or config files in a volume.
a cm allows you to decouple env specific configuration from your container images so that your applications are easily portable.

env, envfrom dont hot reload,so they require a pod restart to pick up changes unlike the volume mounts which can take up the changes dynamically.

NOTE** kubectl create configmap my-html-cm --from-file=index.html=./index.html
if you wanna create the cm from a file and give it a explicit name you can use the above command.

each cm us limited to 1Mib
very large cm can slow down pod startup and increase etcd load

tip: split large configs into multiple cms by concern
for big files use pv , object storage or external config service.

as env: pods do not update when the cm changes, you must restart pod to pick up new values.
volumes: the files on the disk canupdat auto  but :
- some apps dont reload config files unless they are designed to.
- for file based cm: ensure your app watches the file or relaod on signal: avoild subPath if you need updates.

Common issues:

Referring to a key that doesn’t exist in the ConfigMap.

Using items with wrong key/path mapping.

Mount path conflicts (e.g., mounting a CM over a directory that already has important files)