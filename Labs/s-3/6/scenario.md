# 1. Exam Scenario

Task:
A deployment named `api-gateway` in the `edge-routing` namespace is configured to auto-scale using a HorizontalPodAutoscaler (HPA) named `gateway-hpa`. 

However, the operations team has reported a complete failure of this microservice:
1. The HPA is failing to calculate metrics and shows `<unknown>` for CPU utilization.
2. The `api-gateway` pods are continuously restarting and never reaching the `Ready` state.
3. Once the pods do manage to stay alive, they log `HTTP 403 Forbidden` errors when attempting to read configuration data from the Kubernetes API.

Troubleshoot and resolve all issues in the sequence they appear.

When fully operational:
1. The HPA must be able to calculate CPU metrics (this requires a specific configuration in the deployment).
2. The `api-gateway` pods must successfully survive their long boot sequence (the application takes 10 seconds to initialize) and reach the `Running` and `Ready` state.
3. The pods must have the correct RBAC permissions to `get` and `list` ConfigMaps in the `edge-routing` namespace.

# 2. Initial Cluster State

- **Namespaces:** `edge-routing`
- **Deployments:** `api-gateway` (in `edge-routing`)
- **HPA:** `gateway-hpa` (in `edge-routing`)
- **ServiceAccounts:** `gateway-sa` (in `edge-routing`)
- **Roles:** `gateway-role` (in `edge-routing`)
- **RoleBindings:** `gateway-binding` (in `edge-routing`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get hpa -n edge-routing`
```text
NAME          REFERENCE                TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
gateway-hpa   Deployment/api-gateway   <unknown>/50%   1         5         1          3m

Command: kubectl get pods -n edge-routing

Plaintext
NAME                           READY   STATUS    RESTARTS      AGE
api-gateway-6d8b5c9f49-abcde   0/1     Running   4 (21s ago)   2m15s
Command: kubectl describe pod -n edge-routing -l app=gateway

Plaintext
...
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Warning  Unhealthy  12s (x12 over 2m)  kubelet            Startup probe failed: cat: can't open '/tmp/healthy': No such file or directory
  Normal   Killing    12s (x4 over 2m)   kubelet            Container gateway failed startup probe, will be restarted
7. Difficulty
9/10

8. Skills Tested
HorizontalPodAutoscaler (HPA) Prerequisites (resources.requests)

Container Probes (startupProbe vs livenessProbe)

RBAC Authorization (Role verb correction)

Pod Lifecycle and Boot Delays

9. Constraints
Do NOT delete the api-gateway Deployment, HPA, or RBAC resources. Modify them in place.

To fix the HPA, add a CPU request of 100m to the container.

Do NOT change the container's command or args (the 10-second sleep simulates a legacy app booting). Modify the startupProbe configuration to give the application at least 15 seconds to boot before failing.

Ensure the gateway-role has only the minimum required verbs (get, list) for configmaps.

10. Time Estimate
15 - 20 minutes