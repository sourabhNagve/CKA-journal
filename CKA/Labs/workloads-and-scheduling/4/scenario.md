The vault-agent running in the security namespace requires access to an external metadata API located strictly at IP 169.254.169.254 on port 80. Currently, it has unrestricted internet access. Worse, a junior admin mapped the vault-agent ServiceAccount to a ClusterRole Binding that grants it the ability to read Secrets across the entire cluster.

Your Tasks:

Egress Lockdown: Create a NetworkPolicy named vault-egress-strict in the security namespace.

It must target pods labeled app=vault-agent.

It must allow Egress traffic only to the CIDR block 169.254.169.254/32 on TCP port 80.

All other Egress traffic from this pod must be dropped (Note: do not define Ingress rules; rely on implicit isolation behavior if needed, but explicitly define the policyTypes to include Egress).

Revoke Cluster Privilege: Identify and delete the overly permissive ClusterRoleBinding named vault-global-secret-reader.

Least Privilege Binding: Create a standard RoleBinding named vault-local-reader in the security namespace. This must bind the vault-agent ServiceAccount to the pre-existing ClusterRole secret-reader, effectively downgrading the permission scope so the agent can only read secrets within its own security namespace.