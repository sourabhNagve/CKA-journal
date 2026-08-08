The Scenario:
An older payment application exposes an API that must be accessible via [https://payments.acme.corp/api/v1/pay/](https://payments.acme.corp/api/v1/pay/). The routing relies on a legacy Nginx Ingress Controller resource. Currently, external clients are receiving 404s and 502s.

Ingress Rewrite: The ingress resource payments-ingress in the finance namespace is attempting to strip the /api/v1/pay prefix and pass the remainder to the backend. However, the regex annotation and rewrite target are misconfigured. Fix them so that /api/v1/pay/process routes to /process on the backend. (Use Nginx rewrite-target standard logic).

TLS Termination: Secure the ingress using the existing TLS Secret named payments-tls. The host must be exactly payments.acme.corp.

Service Port Mapping: The backing Service payments-svc is a NodePort. It is currently pointing its targetPort to 8443, but the pods actually listen on 8080. Fix the targetPort so endpoints connect.

NodePort Pinning: The NodePort is currently randomized. You must explicitly pin the NodePort to 32123.