Readiness probe:
is this pod ready to recieve traffic,if it failts k8s removes the pod from the service endpoints , so new request stop going to it.

Liveness probe:
is this container still alive, if it fails k8s restarts the container.
