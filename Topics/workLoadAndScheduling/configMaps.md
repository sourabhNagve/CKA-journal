ConfigMap is an api object to store non-confidential data in key-value pairs.
Pods can consume cm as env, command line arguments, or config files in a volume.
a cm allows you to decouple env specific configuration from your container images so that your applications are easily portable.

env, envfrom dont hot reload,so they require a pod restart to pick up changes unlike the volume mounts which can take up the changes dynamically.

NOTE** kubectl create configmap my-html-cm --from-file=index.html=./index.html
if you wanna create the cm from a file and give it a explicit name you can use the above command.