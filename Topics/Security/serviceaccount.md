# service account token
pods dont run by users, they are run via serviceaccounts, there are default service account which are given to the pods which dont specify it manually, those service accounts are used to authenticate to the api server.
kubernetes mounts a service account token into the pod automatically in many cases, so the application inside the pod can talk to the api server.
the path insdie the pod is /var/run/secrets/kubernetes.io/serviceaccount/token
example :curl -s --header "Authorization: Bearer $TOKEN" \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  https://kubernetes.default.svc/api

  **NOTE
  Not every Pod actually needs a token. If the application never talks to the Kubernetes API, best practice is often to disable automatic mounting of the service account token to reduce risk