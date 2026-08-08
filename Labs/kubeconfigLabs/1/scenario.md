Context:
You have been hired to audit and fix the local Kubernetes access configurations for a DevOps engineer who left the company abruptly. Their configuration files are scattered and partially broken.

Task:
Perform all operations without modifying the original /opt/course/kubeconfigs/internal.yaml and /opt/course/kubeconfigs/external.yaml files. Your final working configuration must be saved entirely in /opt/course/kubeconfigs/merged.yaml.

Merge: Merge the configurations from /opt/course/kubeconfigs/internal.yaml and /opt/course/kubeconfigs/external.yaml into a single file located at /opt/course/kubeconfigs/merged.yaml.

Repair: Inside merged.yaml, there is a cluster named cluster-broken. Its API server is currently pointing to port 8443. Fix it so it points to 6443.

Add User: Add a new user named dev-user to merged.yaml. This user should authenticate using client certificates, but the certificates must not be embedded (Base64 encoded) in the YAML. Instead, they must reference the files located at /opt/course/certs/dev.crt for the client-certificate and /opt/course/certs/dev.key for the client-key.

Create Context: Create a new context named dev-access in merged.yaml. It must use the cluster external-cluster, the user dev-user, and default to the development namespace.

Set Context: Set the current context of merged.yaml to the newly created dev-access.

Extract: Extract the embedded, Base64-decoded certificate-authority-data for the internal-cluster (from the merged.yaml file) and save the decoded string into a file at /opt/course/certs/internal-ca.crt. 