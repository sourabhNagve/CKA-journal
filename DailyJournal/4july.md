# kubernetes doesnt have way of explicitly creating users like in linux
- we dont create a user object inside the cluster.
- Instead a user is authenticated through an external identity method
- one way is using the client certificates and then grant permission with RBAC.
- The username comes from the certificate's subject such as common name
- the certificate identify the user to the api server
- last the access is controlled by role and rolebindings not by kubernetes  user record(there is'nt one).
more about this  in the official documentation: https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-certificates

---------------------------

# service account token
pods dont run by users, they are run via serviceaccounts, there are default service account which are given to the pods which dont specify it manually, those service accounts are used to authenticate to the api server.
kubernetes mounts a service account token into the pod automatically in many cases, so the application inside the pod can talk to the api server.
the path insdie the pod is /var/run/secrets/kubernetes.io/serviceaccount/token
example :curl -s --header "Authorization: Bearer $TOKEN" \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  https://kubernetes.default.svc/api

  **NOTE
  Not every Pod actually needs a token. If the application never talks to the Kubernetes API, best practice is often to disable automatic mounting of the service account token to reduce risk

  ------------------------------------------------

  We use a deny-all ingress and egress NetworkPolicy as the default security boundary, then add explicit allow rules for the traffic the application actually needs.

  -------------------------------------------------
  debugging dns troubleshooting
   Pod debug-pod in namespace default cannot resolve the service my-service.production.svc.cluster.local
 - kubectl get svc -n production my-service (Check whether the Service exists in the target namespace) 
 - kubectl get endpoints -n production my-service (Check whether the Service has endpoints)
 - nslookup my-service.production.svc.cluster.local (Test DNS from inside the failing Pod or a debug Pod)
 - Check the Pod’s /etc/resolv.conf to confirm the search domains and nameserver are correct
 - kubectl -n kube-system get pods -l k8s-app=kube-dns
 - kubectl -n kube-system logs -l k8s-app=kube-dns
 -If DNS looks fine, check whether a NetworkPolicy is blocking UDP/TCP port 53 to CoreDNS. Egress-deny policies commonly break DNS resolution


[  A clean troubleshooting order is: Service name → Endpoints → Pod DNS config → CoreDNS health → NetworkPolicy ] 


