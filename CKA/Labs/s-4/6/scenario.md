# 1. Exam Scenario

Task:
A security audit has mandated strict zero-trust network isolation for the payment system operating in the `secure-app` namespace.

Currently, a default deny NetworkPolicy (`deny-all`) blocks all ingress and egress traffic in `secure-app`. A junior developer attempted to write a NetworkPolicy named `allow-backend-traffic`, but it is failing:
1. The `frontend` pod cannot communicate with the `backend` pod on port `8080`.
2. The `backend` pod cannot communicate with the PostgreSQL database (`db` pod) running in a separate namespace named `database-ns` on port `5432`.

Troubleshoot and fix the network policies in `secure-app`.

When fully operational:
1. `frontend` pods in `secure-app` must be allowed to make HTTP requests to `backend` pods in `secure-app` on TCP port `8080`.
2. `backend` pods in `secure-app` must be allowed to make database connections to `db` pods in `database-ns` on TCP port `5432`.
3. All other traffic not explicitly allowed must remain blocked by the security policy.

# 2. Initial Cluster State

- **Namespaces:** `secure-app`, `database-ns`
- **Deployments / Pods:** 
  - `frontend` (label `app=frontend`) in `secure-app`
  - `backend` (label `app=backend`) in `secure-app`
  - `db` (label `app=db`) in `database-ns` (with namespace label `name=database-ns`)
- **NetworkPolicies:** `deny-all` and `allow-backend-traffic` (in `secure-app`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get netpol -n secure-app`
```text
NAME                    POD-SELECTOR   AGE
allow-backend-traffic   app=backend    2m
deny-all                <none>         2m

Command: kubectl exec -n secure-app deploy/frontend -- nc -zv -w 2 backend 8080

Plaintext
nc: connect to backend port 8080 (tcp) failed: Connection timed out
7. Difficulty
9/10

8. Skills Tested
Kubernetes NetworkPolicies (Ingress & Egress)

podSelector vs namespaceSelector

Combining selectors (AND vs OR logic in YAML list syntax)

Port specifications (TCP)

9. Constraints
Do NOT delete or modify the deny-all NetworkPolicy.

Modify or recreate allow-backend-traffic in secure-app to establish the required ingress and egress flows.

Pay close attention to namespace selector syntax: combined in one list item (- podSelector:\n    namespaceSelector:) vs separate items (- podSelector:\n  - namespaceSelector:).

10. Time Estimate
15 - 20 minutes