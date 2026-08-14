# kubernetes doesnt have way of explicitly creating users like in linux
- we dont create a user object inside the cluster.
- Instead a user is authenticated through an external identity method
- one way is using the client certificates and then grant permission with RBAC.
- The username comes from the certificate's subject such as common name
- the certificate identify the user to the api server
- last the access is controlled by role and rolebindings not by kubernetes  user record(there is'nt one).
more about this  in the official documentation: https://kubernetes.io/docs/reference/access-authn-authz/authentication/#client-certificates
