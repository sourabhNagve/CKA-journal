Scenario 1: The Gateway API Canary & DNS Blackhole
The Scenario:
A critical production rollout relies on the modern Gateway API for traffic routing. The architecture splits traffic between api-v1 and api-v2. However, the rollout is completely blackholing traffic. Internal microservices are reporting NXDOMAIN errors when trying to resolve cluster-local services, and external traffic to api-v2 is returning HTTP 503s.

Your tasks:

CoreDNS: The internal cluster.local resolution is broken due to a misconfiguration introduced by a junior engineer in the coredns ConfigMap (in the kube-system namespace). Find and remove the invalid plugin block to restore normal DNS resolution. Restart the CoreDNS pods to apply the fix.

Service Endpoints: The api-v2 Service is detached from its Pods due to a labeling mismatch. Fix the Service so it properly maps to the api-v2 pods on port 80.

Gateway API Routing: The HTTPRoute named api-canary-route in the default namespace is configured incorrectly. Fix the backend references and adjust the traffic split so that exactly 70% of traffic routes to api-v1 and 30% routes to api-v2.

Constraints:

Do not delete and recreate the Gateway or GatewayClass.

The api-canary-route must use the gateway.networking.k8s.io/v1 API.