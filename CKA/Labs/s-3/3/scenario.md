# 1. Exam Scenario

Task:
A deployment named `secret-auditor` has been deployed into the `security-audit` namespace. Its purpose is to periodically query the Kubernetes API Server to list Secrets within its own namespace.

Currently, the deployment is in a `CrashLoopBackOff` state. It is suffering from multiple layers of misconfiguration involving Pod authentication, Network routing, and RBAC authorization.

Troubleshoot and resolve all issues sequentially.

When fully operational:
1. The pod must securely mount its ServiceAccount token.
2. The pod must successfully reach the API server through the existing NetworkPolicy.
3. The pod must have the correct RBAC permissions to list Secrets in the `security-audit` namespace.
4. The pod logs must display `SUCCESS: Secrets retrieved`.

# 2. Initial Cluster State

- **Namespaces:** `security-audit`
- **Deployments:** `secret-auditor` (in `security-audit`)
- **ServiceAccounts:** `auditor-sa` (in `security-audit`)
- **Roles:** `auditor-role` (in `security-audit`)
- **RoleBindings:** `auditor-binding` (in `security-audit`)
- **NetworkPolicies:** `audit-netpol` (in `security-audit`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n security-audit`
```text
NAME                              READY   STATUS             RESTARTS      AGE
secret-auditor-5b7d9b9f8-abcde    0/1     CrashLoopBackOff   3 (14s ago)   85s

Command: kubectl logs -n security-audit deploy/secret-auditor

Plaintext
FAIL: No token mounted
(Note: Once you fix the token mounting issue, the pod will restart and attempt to connect to the API server. You will then see network timeout errors (HTTP 000). Once the network policy is fixed, you will see authorization errors (HTTP 403) until the RBAC is corrected).

7. Difficulty
9.5/10

8. Skills Tested
ServiceAccount Token Mounting (automountServiceAccountToken)

NetworkPolicies (Egress rules and default-deny configurations)

RBAC Troubleshooting (RoleBinding Subjects)

API Server Authentication & Authorization

9. Constraints
Do NOT delete the secret-auditor Deployment. Modify it in place.

Do NOT delete the audit-netpol NetworkPolicy. Modify it to explicitly allow Egress to TCP port 443. Do NOT create a blanket "allow-all" Egress rule.

Modify the existing auditor-binding RoleBinding; do not create a new one.

Adhere to the principle of least privilege.

10. Time Estimate
15 - 20 minutes