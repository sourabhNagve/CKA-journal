# 1. Exam Scenario

Task:
A junior engineer attempted to update the `cart-backend` deployment in the `cart-system` namespace. However, the rollout is completely stuck, and the application is currently experiencing 100% downtime because all old pods were terminated before the new ones became ready.

Additionally, the application relies on an external legacy cache. A headless Service named `external-cache` was created to represent this legacy system, but no traffic can reach it because it fails DNS resolution. 

Troubleshoot and resolve all issues to restore the `cart-backend` application. 

When fully operational:
1. The `cart-backend` pods must be `Running` and `Ready`.
2. The deployment must be configured to prevent total downtime during future rollouts (ensure at least 75% of desired pods remain available during updates).
3. The `external-cache` Service must successfully resolve via DNS without using a selector. Map it to the arbitrary IP `10.20.30.40`.

# 2. Initial Cluster State

- **Namespaces:** `cart-system`
- **Deployments:** `cart-backend` (in `cart-system`)
- **Services:** `external-cache` (in `cart-system`, Headless)
- **Secrets:** `cart-secrets` (in `cart-system`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n cart-system`
```text
NAME                            READY   STATUS                  RESTARTS   AGE
cart-backend-67b8cc7f49-abcde   0/1     Init:0/1                0          3m
cart-backend-67b8cc7f49-vwxyz   0/1     Init:0/1                0          3m

(Notice there are no old pods running, causing a complete outage).

Command: kubectl logs -n cart-system deploy/cart-backend -c wait-for-cache

Plaintext
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find external-cache.cart-system.svc.cluster.local: NXDOMAIN

waiting for DNS...
(Note: Once you fix the DNS/Service issue, the init container will pass, but the main container will fail to start due to configuration errors, and subsequently fail readiness checks. You must fix all layers).

7. Difficulty
9/10

8. Skills Tested
Headless Services & Manual Endpoints mapping

Deployment Rollout Strategies (maxUnavailable / maxSurge)

Secrets & secretKeyRef Troubleshooting

Readiness Probes

Zero-Downtime Update principles

9. Constraints
Do NOT delete the cart-backend Deployment or the external-cache Service; modify them in place.

Do NOT add a selector to the external-cache Service.

The cart-backend Deployment has 4 desired replicas. Modify the strategy so that no more than 1 replica is taken down at a time during an update (leaving 75% available).

The arbitrary legacy cache IP must be exactly 10.20.30.40.