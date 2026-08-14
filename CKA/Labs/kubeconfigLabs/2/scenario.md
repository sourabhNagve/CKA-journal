Context:
A senior administrator has left the team and handed over a bloated, multi-environment kubeconfig file. Security policies mandate that all embedded client certificates/keys must be stored as separate files, and legacy clusters must be purged. Furthermore, the development team needs a lightweight kubeconfig containing only what they need.

Task:
The starting configuration file is located at /opt/course/kube/config.yaml.
First, make a copy of this file to /opt/course/kube/clean-config.yaml. Perform all modifications (Tasks 1-4) on clean-config.yaml.

Cleanup: Delete the cluster named legacy-cluster and its associated context legacy-ctx from the clean-config.yaml file.

Extraction: The user prod-admin currently uses embedded, Base64-encoded client-certificate-data and client-key-data. Extract these values, decode them, and save them to /opt/course/kube/prod.crt and /opt/course/kube/prod.key respectively.

Reconfiguration: Modify the prod-admin user in clean-config.yaml so it no longer uses embedded data. Instead, configure it to reference the newly created file paths /opt/course/kube/prod.crt and /opt/course/kube/prod.key.

Namespace Update: Update the existing staging-ctx context in clean-config.yaml to set its default namespace to qa-environment.

Minification: Create a brand new, isolated kubeconfig file at /opt/course/kube/dev-only.yaml. This file must contain only the cluster, user, and context required for dev-ctx (which are dev-cluster and dev-user). It must not contain any information about prod or staging.