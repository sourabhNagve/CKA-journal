for internal service discovery:
Svc-name.namespace.svc.cluster.local 
- cluster.local is the domain name in the cluster
- svc is the service name

Connecting to External Services:
How do you map an external FQDN (like a managed AWS RDS database) to an internal Kubernetes service so your pods can use a local name?
Create a Service of type ExternalName. This acts as an alias. When a pod queries the internal service, CoreDNS returns a CNAME record pointing to the external FQDN.

YAML
apiVersion: v1
kind: Service
metadata:
  name: my-database
  namespace: production
spec:
  type: ExternalName
  externalName: db1.xyz.eu-west-1.rds.amazonaws.com

  Pods can now connect to my-database.production.svc.cluster.local, and Kubernetes handles forwarding it to the AWS RDS FQDN.

  -----------------------
  # k exec -it internal-client -n internal -- wget app-9000-service.fubar.svc.cluster.local:9000 vs kubectl exec -n internal internal-client -- wget -qO- --timeout=2 app-9000-service.fubar.svc.cluster.local:9000.
the first command shows error because its executed in tty mode, 
wget -qO- --timeout=2 ...
Option	What it does
-q	Quiet mode → no progress meter, no verbose output 
-O-	Output the response to stdout (so you see it on screen) 
--timeout=2	If the connection takes more than 2 seconds, wget stops instead of waiting forever 