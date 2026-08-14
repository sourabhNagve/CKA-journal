Scenario 5: The EnvPrefix Collision & Zero-Trust Pivot
1. The Scenario
The data-sync workload in the etl-jobs namespace needs to connect to two different databases (Primary and Replica). The database team has provided two separate Secrets: db-creds-primary and db-creds-replica. Both secrets use the exact same keys (USERNAME and PASSWORD). If you mount them directly, they will overwrite each other in the container's environment variables.
Additionally, the security team mandates that this deployment run under a strict zero-trust model, as it currently uses the highly permissive default ServiceAccount.

Your Tasks:

Zero-Trust SA: Create a ServiceAccount named etl-runner in the etl-jobs namespace.

Automount Denial: Configure the data-sync deployment to use the etl-runner ServiceAccount, and explicitly disable the mounting of the Kubernetes API token (automountServiceAccountToken: false).

Resolve Secret Collisions: Remove the existing hardcoded environment variables. Use envFrom to load both Secrets (db-creds-primary and db-creds-replica) as environment variables.

Prefixing: To prevent the keys from overwriting each other, configure the envFrom declarations to append the prefix PRI_ to the primary secret, and REP_ to the replica secret.