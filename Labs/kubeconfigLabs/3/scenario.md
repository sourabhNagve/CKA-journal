Context:
You have just joined an SRE team. They provide access to three different environments (Dev, Test, and Prod), but the kubeconfigs were distributed as three separate files. Additionally, some of the configurations are misaligned, missing certificates, or use outdated naming conventions.

Task:
The environment files are located in /opt/course/kube3/: dev.yaml, test.yaml, and prod.yaml.
Your final, fixed configuration must be saved to /opt/course/kube3/master.yaml.

Merge: Combine dev.yaml, test.yaml, and prod.yaml into a single file at /opt/course/kube3/master.yaml. Perform all remaining tasks on master.yaml.

Context Repair: The context test-ctx was misconfigured and is currently trying to authenticate using the dev-user. Modify test-ctx so that it uses the test-user.

Embed Certificates: The prod-cluster is missing its Certificate Authority data. A valid CA certificate is located at /opt/course/kube3/prod-ca.crt. Update the prod-cluster in master.yaml to include this CA certificate. The certificate data must be embedded (Base64 encoded) directly inside master.yaml.

Rename Context: The team is standardizing context names. Rename the dev-ctx context to development-context in master.yaml.

JSONPath Query: One of the contexts in master.yaml has its default namespace set to database. Find out which context this is, and write the name of the context to /opt/course/kube3/db-context.txt.