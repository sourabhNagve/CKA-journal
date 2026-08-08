Context:
A new bare-metal cluster has been provisioned. The provisioning tool generated raw certificate files and a bearer token, but it failed to generate a kubeconfig file. You must build a completely new kubeconfig file from scratch for the team to use, without copying an existing template.

Task:
Create a brand new kubeconfig file located at /opt/course/kube4/custom-config.yaml that satisfies all of the following requirements:

Cluster: Add a cluster named omega-cluster. Its API server URL is [https://172.16.0.100:6443](https://172.16.0.100:6443). It must use the Certificate Authority file located at /opt/course/kube4/ca.crt. The CA certificate must be embedded (Base64 encoded) inside the kubeconfig.

Admin User: Add a user named cluster-admin. This user authenticates via client certificates. Use the files /opt/course/kube4/admin.crt and /opt/course/kube4/admin.key. These certificates must be embedded inside the kubeconfig.

Dev User: Add a second user named dev-user. This user does not use certificates; instead, they authenticate using a Bearer Token. The token value to configure is dev-token-999xyz.

Admin Context: Create a context named admin-system. It must link the omega-cluster and the cluster-admin user, and set the default namespace to kube-system.

Dev Context: Create a context named dev-apps. It must link the omega-cluster and the dev-user, and set the default namespace to applications.

Active Context: Set the current, active context of this new kubeconfig to dev-apps.

Extraction: Using kubectl config view and JSONPath against your newly created custom-config.yaml, extract the token value for dev-user and save it to /opt/course/kube4/extracted-token.txt.

(Note: You must build this file dynamically. Do not manually write the YAML structure in vi/nano)

.spec.containers.resources