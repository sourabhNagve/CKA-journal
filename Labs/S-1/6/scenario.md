# 1. Exam Scenario

Task:
A standalone pod named `report-generator` runs in the `legacy-ops` namespace. It is designed to continuously fetch data from an internal API service (`api-svc`) located in the `internal-api` namespace.

Currently, the `report-generator` pod is in a `CrashLoopBackOff` state due to network communication failures. A strict egress firewall (NetworkPolicy) was recently applied to the namespace, which has broken the pod's ability to resolve internal DNS and reach the target service.

Additionally, the development team has requested a configuration change and a network exposure change.

Resolve the issues by completing the following tasks:
1. Fix the network isolation issue so the `report-generator` pod can successfully resolve internal DNS and make HTTP requests to `api-svc.internal-api.svc.cluster.local`.
2. Add a new environment variable `API_VERSION=v2` to the `report-generator` pod.
3. Modify the existing `report-svc` Service in the `legacy-ops` namespace to expose the application externally using a `NodePort` on port `32000`.

# 2. Initial Cluster State

- **Namespaces:** `legacy-ops`, `internal-api`
- **Deployments:** `api-server` (in `internal-api`)
- **Pods:** `report-generator` (Naked pod in `legacy-ops`)

- **Services:** `api-svc` (in `internal-api`), `report-svc` (in `legacy-ops`)
- **NetworkPolicies:** `legacy-egress-deny` (in `legacy-ops`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n legacy-ops`
```text
NAME               READY   STATUS             RESTARTS      AGE
report-generator   0/1     CrashLoopBackOff   4 (82s ago)   3m12s

Command: kubectl logs report-generator -n legacy-ops

Plaintext
Fetching report data...
curl: (6) Could not resolve host: api-svc.internal-api.svc.cluster.local
Error: Failed to reach API. Exiting.
Command: kubectl get svc -n legacy-ops

Plaintext
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
report-svc   ClusterIP   10.101.124.230   <none>        80/TCP    3m15s
7. Difficulty
9/10

8. Skills Tested
Immutable Pod Workarounds (Naked Pod Recreation)

Advanced NetworkPolicies (Default Deny Egress, DNS resolution)

Services (Converting to NodePort with specific port)

Troubleshooting DNS & Cross-Namespace Routing

9. Constraints
Do NOT delete or modify resources in the internal-api namespace.

Do NOT use a "default-allow-all" NetworkPolicy. You must explicitly allow only the necessary egress traffic (DNS to kube-system and HTTP to internal-api).

The report-generator pod is NOT managed by a Deployment. You must safely delete and recreate it while preserving its existing properties (adding only the new environment variable).

The report-svc MUST retain its current selector and target port.