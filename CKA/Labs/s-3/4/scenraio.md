# 1. Exam Scenario

Task:
A recent update by the platform team has caused a massive cluster-wide outage. The internal cluster DNS resolution is completely broken.

Furthermore, a critical deployment named `auth-service` in the `auth-ns` namespace is failing to start. It relies on a database service named `db-service` in the `db-ns` namespace.

Troubleshoot and resolve all issues in the cluster.

When fully operational:
1. The cluster's CoreDNS pods must be back in the `Running` state.
2. The `auth-service` pod must successfully resolve internal Kubernetes DNS.
3. The `auth-service` pod must reach the `Running` state.
4. The `db-service` must correctly route traffic to the database pod.

# 2. Initial Cluster State

- **Namespaces:** `auth-ns`, `db-ns`, `kube-system`
- **Deployments:** `auth-service` (in `auth-ns`), `db-backend` (in `db-ns`)
- **Services:** `db-service` (in `db-ns`)
- **ConfigMaps:** `coredns` (in `kube-system`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n kube-system -l k8s-app=kube-dns`
```text
NAME                       READY   STATUS             RESTARTS      AGE
coredns-64897985d-abcde    0/1     CrashLoopBackOff   4 (35s ago)   2m
coredns-64897985d-vwxyz    0/1     CrashLoopBackOff   4 (35s ago)   2m

Command: kubectl logs -n kube-system -l k8s-app=kube-dns

Plaintext
plugin/errors: 2 <nil> 
CoreDNS-1.8.6
linux/amd64, go1.17.1, 13a9191
Error during parsing: /etc/coredns/Corefile:4 - Error during parsing: Unknown directive 'brokenhealth'
Command: kubectl get pods -n auth-ns

Plaintext
NAME                            READY   STATUS     RESTARTS   AGE
auth-service-78f9c5d89b-abcde   0/1     Init:0/1   0          3m
7. Difficulty
9.5/10

8. Skills Tested
Cluster DNS Troubleshooting (CoreDNS ConfigMaps)

Pod DNS Policies (dnsPolicy)

Service Selectors and Endpoints mapping

Init Container debugging

9. Constraints
Do NOT delete or recreate the coredns Deployment. Modify the existing coredns ConfigMap to fix the syntax error.

Do NOT delete the auth-service deployment; modify it in place.

Do NOT change the command of the init container in auth-service.

The db-service must retain its name and port configurations.

10. Time Estimate
15 - 20 minutes