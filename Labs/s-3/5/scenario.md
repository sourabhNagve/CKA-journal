YET TO DO
# 1. Exam Scenario

Task:
A junior administrator attempted to update the cluster's network routing configuration and deploy a new secure payment application in the `payments` namespace. 

Since their changes, multiple systems are failing:
1. The cluster's `kube-proxy` component is crash-looping, breaking all Service routing across the cluster.
2. The `payment-processor` Deployment is stuck and unable to schedule all of its requested replicas.
3. The `payment-ingress` is failing to serve the custom TLS certificate because the corresponding Secret is misconfigured.

Troubleshoot and resolve all issues in the cluster.

When fully operational:
1. The `kube-proxy` pods in the `kube-system` namespace must be in the `Running` state.
2. The `payment-processor` deployment must have all 5 replicas in the `Running` state. Modify its scheduling constraints so that it *prefers* to spread pods evenly across nodes, but will schedule them anyway if it cannot.
3. The `payment-tls` Secret must be recreated as the correct type (`kubernetes.io/tls`). The raw certificate and key files have been left on the control-plane node at `/opt/payment-certs/tls.crt` and `/opt/payment-certs/tls.key`.

# 2. Initial Cluster State

- **Namespaces:** `payments`, `kube-system`
- **Deployments:** `payment-processor` (in `payments`)
- **DaemonSets:** `kube-proxy` (in `kube-system`)
- **Ingresses:** `payment-ingress` (in `payments`)
- **Secrets:** `payment-tls` (in `payments`)
- **Certificates Location:** `/opt/payment-certs/`

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n kube-system -l k8s-app=kube-proxy`
```text
NAME               READY   STATUS             RESTARTS      AGE
kube-proxy-abcde   0/1     CrashLoopBackOff   4 (42s ago)   3m

Command: kubectl get pods -n payments

Plaintext
NAME                                READY   STATUS    RESTARTS   AGE
payment-processor-6c8f9b9d-12345    1/1     Running   0          3m
payment-processor-6c8f9b9d-67890    0/1     Pending   0          3m
payment-processor-6c8f9b9d-abcde    0/1     Pending   0          3m
payment-processor-6c8f9b9d-vwxyz    0/1     Pending   0          3m
payment-processor-6c8f9b9d-zzzzz    0/1     Pending   0          3m
Command: kubectl describe secret payment-tls -n payments

Plaintext
Name:         payment-tls
Namespace:    payments
Labels:       <none>
Annotations:  <none>

Type:  Opaque  <-- (This is incorrect for an Ingress TLS secret)
...
7. Difficulty
10/10

8. Skills Tested
Cluster Component Troubleshooting (kube-proxy ConfigMaps)

Advanced Scheduling (topologySpreadConstraints)

Ingress Configuration & TLS Certificates

Secret Types (kubernetes.io/tls vs Opaque)

9. Constraints
Do NOT delete or recreate the kube-proxy DaemonSet. Fix the underlying ConfigMap.

Do NOT delete the payment-processor Deployment; modify it in place.

Do NOT remove the topologySpreadConstraints block from the deployment; you must change its whenUnsatisfiable behavior.

You MUST delete and recreate the payment-tls Secret using the exact same name, pulling the certs from /opt/payment-certs/.

10. Time Estimate
20 - 25 minutes