A pod was not running because it depended on a database pod.
The pod had two containers:

api (main container)

wait-for-db (sidecar/init-style container checking DB connectivity)

The wait-for-db container continuously attempted to connect to the database. Since the connection never succeeded, the main container never started.

mostly it is because of Incorrect Service selector labels (no endpoints created)

Misconfigured NetworkPolicy (blocking traffic)

Needed to verify connectivity from inside the pod.

pods/exec is a subresource: A subresource is a separate API endpoint for a specific part or action of a Kubernetes resource, rather than the main resource itself. For example, pods/exec is the exec subresource of a Pod, used to open a command session inside the container.

Check permission:
k auth can-i create pods --subresource=exec -n finance-db --serviceaccount=finance-db:db-troubleshooter

whenever there is init 0/1 error, there is problem with the init container not starting preventing the main app to start.

