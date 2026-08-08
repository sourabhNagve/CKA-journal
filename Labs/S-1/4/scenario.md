# 1. Exam Scenario

Task:
A two-tier application consists of a `frontend-app` and a `backend-api` in the `secure-corp` namespace. The deployment uses strict NetworkPolicies to isolate traffic. 

Currently, the application is completely broken:
1. The `backend-api` pods are failing to start.
2. The `frontend-app` cannot communicate with the `backend-api`.
3. External clients (simulated by pods in other namespaces) cannot access the `frontend-app` via its NodePort service.

Troubleshoot and resolve all issues so that:
- The `backend-api` pods reach the `Running` state.
- The `frontend-app` pods can successfully communicate with `backend-svc` on port 80.
- Any pod in any namespace can access the `frontend-svc` Service on port 80.

# 2. Initial Cluster State

- **Namespaces:** `secure-corp`
- **Deployments:** `frontend-app`, `backend-api`
- **Services:** `frontend-svc`, `backend-svc`
- **NetworkPolicies:** `frontend-netpol`, `backend-netpol`
- **Secrets:** `db-creds-v2`

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n secure-corp`
```text
NAME                            READY   STATUS                       RESTARTS   AGE
backend-api-7c9b5d6b49-xabcd    0/1     CreateContainerConfigError   0          4m
backend-api-7c9b5d6b49-ybcde    0/1     CreateContainerConfigError   0          4m
frontend-app-55d8f764b8-zvwxy   1/1     Running                      0          4m




8. Skills Tested
Advanced NetworkPolicies (Ingress & Egress)

Cross-namespace communication rules

Troubleshooting Pod mounting & Secrets (CreateContainerConfigError)

Label Selectors and Service Endpoints

9. Constraints
Do NOT delete the backend-api or frontend-app Deployments; modify them in place.

Do NOT delete existing NetworkPolicies; modify them to fix the traffic flows.

Do NOT change the labels of the frontend-app or backend-api Pods.

Do NOT use a default-allow-all NetworkPolicy. You must explicitly allow the required traffic paths.

Preserve the NodePort configuration on frontend-svc.