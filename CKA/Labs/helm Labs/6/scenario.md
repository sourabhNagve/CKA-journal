### exam-question.md

# 1. Exam Scenario

Task:
A deployment managed by Helm named `payment-gateway` in the `payments` namespace is currently broken and inaccessible after a recent update by a junior platform engineer.

You must investigate and restore the application to a fully functional state by performing a Helm upgrade. 

Ensure the following requirements are met:
1. The application pods must successfully start and enter the `Running` state.
2. The deployment must use the `nginx:1.25.3` image.
3. The application must comply with the existing default-deny `NetworkPolicy`. To receive internal traffic, the pods must be assigned the label `security-tier: restricted`.
4. The deployment's ServiceAccount must have the necessary RBAC permissions to read secrets in the `payments` namespace, which is currently causing an initialization failure.

You must fix these issues exclusively by updating the Helm release. The chart is stored locally on the controlplane node at `/opt/helm-charts/payment-gateway`. 

# 2. Initial Cluster State

- **Namespaces**: `payments`
- **Helm Releases**: `payment-gateway` (Status: deployed, but pods are failing)
- **Deployments**: `payment-gateway`
- **Secrets**: `db-credentials`
- **NetworkPolicies**: `default-deny-payments`, `allow-restricted-internal`
- **ServiceAccounts**: `payment-gateway-sa`
- **Roles/RoleBindings**: Created via Helm chart

# 6. Expected kubectl Outputs

**kubectl get pods -n payments**
```text
NAME                               READY   STATUS                  RESTARTS      AGE
payment-gateway-5c778b7b4d-kx9zq   0/1     Init:CrashLoopBackOff   4 (81s ago)   3m
kubectl logs payment-gateway-5c778b7b4d-kx9zq -c check-secret -n payments

Plaintext
Error from server (Forbidden): secrets "db-credentials" is forbidden: User "system:serviceaccount:payments:payment-gateway-sa" cannot get resource "secrets" in API group "" in the namespace "payments"
(After fixing RBAC): kubectl get pods -n payments

Plaintext
NAME                               READY   STATUS             RESTARTS   AGE
payment-gateway-6d889c8c5e-abc12   0/1     ImagePullBackOff   0          45s
7. Difficulty
9/10

8. Skills Tested
Helm Troubleshooting & Upgrades

Helm values overrides (values.yaml / --set)

Role-Based Access Control (RBAC)

NetworkPolicies and Pod Selectors

InitContainers troubleshooting

Image resolution

9. Constraints
Do not delete or manually edit (kubectl edit) the existing Deployment, Role, or RoleBinding. You MUST use helm upgrade.

Existing NetworkPolicy resources must remain completely unchanged.

You must use the local chart provided at /opt/helm-charts/payment-gateway.

10. Time Estimate
15-20 minutes