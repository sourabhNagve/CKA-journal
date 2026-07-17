validatingwebhookconfiguration is  a k8s resource which tells api server to call and external validation service before allowing certain actions like creating or updating resource.

when someone sends the request to the k8s api, the webhook gets teh object and returns either deny or allo.
if the webhook denies the request, k8s blocks the chnage and usually returns a message explaining why.

why does it used:
- it is used to enforce custom rules which by default k8s doesnt enforce
examples: reuired labels or annotations, image restrictions, resource limits, naming rules, policy checks for specific custom resources.

If your policy says “every Pod must have CPU and memory limits,” a validating webhook can reject any Pod that does not meet that rule
A validating webhook only checks the request and can reject it.
It does not modify the object; that is the job of a mutating webhook


yaml example 
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: validate-pods.example.com
webhooks:
- name: validate-pods.example.com
  admissionReviewVersions: ["v1"]
  sideEffects: None
  failurePolicy: Fail
  matchPolicy: Equivalent
  clientConfig:
    service:
      name: webhook-service
      namespace: default
      path: /validate
    caBundle: ""
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]

    here the clientConfig.service this points the api server to the webhook service that will recieve the validating requests.
rules says which objects and actions should be validated, here Pods on create and update.
failurePolicy: Fail means if the webhook is unreachable, Kubernetes rejects the request rather than letting it through

Note** In a real cluster, caBundle must contain the base64-encoded CA certificate for the webhook TLS cert; leaving it empty is only fine for a simplified example
 
 a webhook setup consists of webhook service , webhookconfig, and the webhook server deployment
 all this is used just to prevent lets say a pod or deployment to stop their formation if they dont have example labels, so webhooks are just checks for them and allow us to deny or allow.


 working:- The API server uses the ValidatingWebhookConfiguration to find the Service and path for the validation endpoint.
 The Service forwards traffic to the webhook Pod, and the Pod serves HTTPS using the TLS cert from a Secret
