# 1. Exam Scenario

Task:
Your organization is migrating to the modern Kubernetes Gateway API and enforcing strict security compliance on all new workloads. You must configure the routing and deploy a highly secure backend application in the `secure-vault` namespace.

Perform the following tasks sequentially:

1. **ServiceAccount:** Create a ServiceAccount named `vault-sa` in the `secure-vault` namespace.
2. **Secure Pod Deployment:** Create a Pod named `vault-backend` with the following strict requirements:
   - It must use the `vault-sa` ServiceAccount.
   - It must have an `emptyDir` volume named `shared-data`.
   - **InitContainer:** Add an init container named `setup-vault` using the `busybox` image. It must mount the `shared-data` volume at `/data` and run the command `touch /data/initialized.txt` to successfully complete.
   - **Main Container:** Use the `nginx:alpine` image. Mount the `shared-data` volume at `/data`. 
   - **SecurityContext:** Configure the main `nginx` container's security context to run as user ID `1000`. Drop `ALL` Linux capabilities, but explicitly add the `NET_BIND_SERVICE` capability so it can bind to port 80.
3. **Service:** Expose the Pod internally by creating a Service named `vault-svc` routing TCP port 80 to the Pod's port 80.
4. **Gateway API (Routing):** 
   - A `GatewayClass` named `internal-gw-class` already exists at the cluster level.
   - Create a `Gateway` named `vault-gateway` in the `secure-vault` namespace, using the `internal-gw-class`, listening on port `80` (HTTP).
   - Create an `HTTPRoute` named `vault-route` in the `secure-vault` namespace. It must attach to `vault-gateway` and route all traffic matching the exact path `/vault` to the `vault-svc` service on port 80.

When fully operational:
1. The `vault-backend` pod must be `Running` (meaning the InitContainer succeeded and the main container started).
2. The Pod must run as user `1000` with the correct capabilities.
3. The Gateway and HTTPRoute must be correctly configured to route traffic.

# 2. Initial Cluster State

- **Namespaces:** `secure-vault`
- **GatewayClass:** `internal-gw-class` (Cluster-scoped, pre-existing)
- **CRDs:** Gateway API v1.0 CRDs are already installed on the cluster.

# 6. Expected kubectl Outputs

**Command:** `kubectl get pod vault-backend -n secure-vault`
```text
NAME            READY   STATUS    RESTARTS   AGE
vault-backend   1/1     Running   0          2m

Command: kubectl get httproute vault-route -n secure-vault

Plaintext
NAME          HOSTNAMES   AGE
vault-route               2m
7. Difficulty
10/10

8. Skills Tested
Gateway API (Gateway and HTTPRoute resources)

InitContainers (Lifecycle execution)

Container SecurityContexts (runAsUser, capabilities)

ServiceAccounts (Pod assignment)

9. Constraints
The nginx:alpine image requires NET_BIND_SERVICE to run on port 80 if not running as root (UID 0). You must structure the securityContext correctly.

Gateway API resources cannot be generated via imperative commands (kubectl create ...). You must write the YAML manifests from scratch or use documentation snippets.

10. Time Estimate
20 - 25 minutes