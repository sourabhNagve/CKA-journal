# 1. Exam Scenario

Task:
Your organization is expanding the cluster and migrating to dynamically provisioned infrastructure and third-party Helm charts. You have been tasked with preparing the cluster for a new worker node, deploying a web fleet via Helm, creating dynamic storage, and configuring a Custom Resource.

Perform the following tasks sequentially:

1. **Node Bootstrapping:** Generate the exact command required to join a new worker node to this cluster. Save the output string to `/opt/join-command.txt`. 
2. **Helm Deployment:** 
   - Add the Bitnami Helm repository (`https://charts.bitnami.com/bitnami`).
   - Use Helm to install the `apache` chart from the bitnami repository into the `web-fleet` namespace. 
   - Name the Helm release `frontend-web`.
3. **Dynamic Volume Provisioning:** 
   - A `StorageClass` named `fast-storage` has been pre-configured on the cluster. 
   - Create a PersistentVolumeClaim named `dynamic-pvc` in the `web-fleet` namespace that requests `1Gi` of storage using the `fast-storage` storage class. *(Note: It is expected to remain in the `Pending` state in this lab environment since there is no actual external cloud provisioner attached).*
4. **Custom Resources (CRD):** 
   - A CustomResourceDefinition (CRD) for a resource kind `CronTab` (`crontabs.stable.example.com`) has been installed on the cluster.
   - Create a Custom Resource named `nightly-backup` of kind `CronTab` in the `web-fleet` namespace.
   - The resource must have the following properties under `spec`:
     - `cronSpec`: `"* * * * *"`
     - `image`: `backup-image:v1`

When fully operational:
1. The join command is saved to the file.
2. The Helm release is successfully deployed.
3. The PVC is created and linked to the `fast-storage` class.
4. The Custom Resource is present in the namespace.

# 2. Initial Cluster State

- **Namespaces:** `web-fleet`
- **StorageClasses:** `fast-storage`
- **CRDs:** `crontabs.stable.example.com`

# 6. Expected kubectl / helm Outputs

**Command:** `cat /opt/join-command.txt`
```text
kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>

Command: kubectl get crontab nightly-backup -n web-fleet

Plaintext
NAME             AGE
nightly-backup   2m
7. Difficulty
9/10

8. Skills Tested
Control Plane Admin (kubeadm token create --print-join-command)

Helm Package Manager (helm repo add, helm install)

Dynamic Storage Provisioning (PVC to StorageClass mapping)

CRDs and Custom Resources

9. Constraints
The fast-storage StorageClass is a mock provisioner. Do not worry if the PVC stays Pending; the exam grades based on your PVC configuration, not the external cloud provider's speed.

The CRD API version is stable.example.com/v1.

10. Time Estimate
15 - 20 minutes