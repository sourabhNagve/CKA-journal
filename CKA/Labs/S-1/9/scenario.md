# 1. Exam Scenario

Task:
A highly critical deployment named `gateway-app` was deployed into the `edge-net` namespace. It is configured to run exactly 3 replicas, strictly on nodes meant for edge workloads, and with anti-affinity rules to prevent single-node failure impacts.

However, the deployment is currently failing to reach 3 healthy replicas, and external clients cannot reach the application via the Ingress. 

Troubleshoot and resolve all issues. You will need to address scheduling constraints, pod lifecycle issues, and routing misconfigurations. 

When fully operational:
1. Exactly 3 `gateway-app` pods must be in the `Running` state and passing all health checks.
2. The Ingress resource must correctly route traffic to the `gateway-svc` Service.

# 2. Initial Cluster State

- **Namespaces:** `edge-net`
- **Deployments:** `gateway-app` (in `edge-net`)
- **Services:** `gateway-svc` (in `edge-net`)
- **Ingresses:** `gateway-ingress` (in `edge-net`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n edge-net`
```text
NAME                           READY   STATUS    RESTARTS   AGE
gateway-app-5d8f6d7c88-abcde   0/1     Pending   0          3m
gateway-app-5d8f6d7c88-fghij   0/1     Pending   0          3m
gateway-app-5d8f6d7c88-klmno   0/1     Pending   0          3m

Command: kubectl describe pod -n edge-net -l app=gateway

Plaintext
...
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  3m    default-scheduler  0/2 nodes are available: 2 node(s) didn't match Pod's node affinity/selector.
(Note: Once you fix the node selection issue, you will see scheduling failures regarding pod anti-affinity, and then CrashLoopBackOffs due to health checks).

7. Difficulty
9/10

8. Skills Tested
Advanced Pod Scheduling (NodeSelectors)

Modifying Affinity/Anti-Affinity rules (required vs preferred)

Application Health (Liveness Probes)

Ingress Troubleshooting & Service binding

9. Constraints
The deployment MUST continue to use a Node Selector targeting tier: edge. You must label at least one worker node in your cluster with this label.

Do NOT scale the deployment down; it must remain at 3 replicas.

Depending on your cluster size, it may be physically impossible to strictly enforce PodAntiAffinity across 3 unique nodes. Modify the deployment's PodAntiAffinity from a "required" constraint to a "preferred" constraint so pods can co-locate if necessary.

Do NOT delete the gateway-app deployment; modify it in place.

Do NOT modify the Ingress host (edge.example.com).