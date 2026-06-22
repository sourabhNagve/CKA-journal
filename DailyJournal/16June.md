# k exec -it internal-client -n internal -- wget app-9000-service.fubar.svc.cluster.local:9000 vs kubectl exec -n internal internal-client -- wget -qO- --timeout=2 app-9000-service.fubar.svc.cluster.local:9000.
the first command shows error because its executed in tty mode, 
wget -qO- --timeout=2 ...
Option	What it does
-q	Quiet mode → no progress meter, no verbose output 
-O-	Output the response to stdout (so you see it on screen) 
--timeout=2	If the connection takes more than 2 seconds, wget stops instead of waiting forever 