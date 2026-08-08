# 1. Exam Scenario

Task:
A new developer, `jane`, is joining the `dev-team` namespace. Her machine has generated a private key and a Certificate Signing Request (CSR), which have been uploaded to your control-plane node at `/opt/jane/jane.key` and `/opt/jane/jane.csr`.

You must onboard her into the cluster by completing the Kubernetes PKI authentication flow and providing her with a working `kubeconfig` file.

Troubleshoot and resolve the access requirements sequentially:
1. Create a Kubernetes `CertificateSigningRequest` resource named `jane-developer` using her provided `.csr` file.
2. Approve the CSR to generate her signed certificate.
3. Grant her user account (`jane`) the ability to `get`, `list`, and `watch` pods strictly within the `dev-team` namespace.
4. Construct a valid kubeconfig file for her at `/opt/jane/jane.kubeconfig` that embeds her key, signed certificate, and cluster details.

When fully operational:
1. The CSR `jane-developer` must be `Approved,Issued`.
2. The user `jane` must have the correct RBAC permissions.
3. Running `kubectl get pods -n dev-team --kubeconfig=/opt/jane/jane.kubeconfig` must succeed without unauthorized or connection errors.

# 2. Initial Cluster State

- **Namespaces:** `dev-team`
- **User Files:** `/opt/jane/jane.key`, `/opt/jane/jane.csr`
- **Target Kubeconfig Path:** `/opt/jane/jane.kubeconfig`

# 6. Expected kubectl Outputs

**Command:** `kubectl get csr jane-developer`
```text
NAME             AGE   SIGNERNAME                                    REQUESTOR          CONDITION
jane-developer   2m    kubernetes.io/kube-apiserver-client           kubernetes-admin   Approved,Issued