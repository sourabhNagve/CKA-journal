# 1. Exam Scenario

Task:
A web application is deployed in the `ecommerce` namespace. Clients are supposed to access it via an Ingress resource using the hostname `shop.example.com`. However, users are reporting `503 Service Unavailable` errors. 

Troubleshoot and resolve all issues preventing traffic from reaching the application. The Ingress must successfully route traffic to the `ecommerce-app` pods.

Additionally, the security team has deployed a DaemonSet named `node-defender` in the `security-ops` namespace. This DaemonSet is strictly required to run on *every* node in the cluster, including the control-plane nodes. Currently, it is failing to schedule on the control plane. 

Fix the scheduling issue so the `node-defender` pod runs on all nodes.

# 2. Initial Cluster State

- **Namespaces:** `ecommerce`, `security-ops`
- **Deployments:** `ecommerce-app` (in `ecommerce`)
- **Services:** `ecommerce-svc` (in `ecommerce`)
- **Ingresses:** `ecommerce-ingress` (in `ecommerce`)
- **DaemonSets:** `node-defender` (in `security-ops`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n ecommerce`
```text
NAME                             READY   STATUS    RESTARTS   AGE
ecommerce-app-548c966589-abcde   0/1     Running   0          5m12s


Command: kubectl describe pod -n ecommerce -l app=ecommerce-app

Plaintext
...
Events:
  Type     Reason     Age                   From               Message
  ----     ------     ----                  ----               -------
  Normal   Scheduled  5m18s                 default-scheduler  Successfully assigned ecommerce/ecommerce-app-548c966589-abcde to worker-node-1
  Warning  Unhealthy  18s (x32 over 5m10s)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 404
Command: kubectl get endpoints ecommerce-svc -n ecommerce

Plaintext
NAME            ENDPOINTS   AGE
ecommerce-svc               5m42s
Command: kubectl get daemonset -n security-ops

Plaintext
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
node-defender   1         1         1       1            1           <none>          6m
(Note: If you have a 2-node cluster with 1 master and 1 worker, DESIRED should be 2, but it currently shows 1 because it cannot schedule on the master).

7. Difficulty
8.5/10

8. Skills Tested
Ingress Configuration & Routing

Pod Readiness Probes

Service Endpoints Troubleshooting

DaemonSet Scheduling

Taints & Tolerations (Control Plane isolation)

9. Constraints
Do NOT delete the ecommerce-app Deployment or node-defender DaemonSet; modify them in place using kubectl edit or kubectl patch.

Do NOT change the image used in the Deployment or DaemonSet.

Do NOT remove taints from the control-plane nodes. You must fix the workload.

The Ingress host shop.example.com must remain unchanged.