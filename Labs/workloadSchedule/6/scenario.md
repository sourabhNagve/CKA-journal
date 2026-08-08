The db-tier namespace houses a highly sensitive PostgreSQL StatefulSet. Due to a misconfiguration, frontend pods from the frontend-tier namespace are currently able to access the database directly. Additionally, an external contractor's ServiceAccount (db-operator) was temporarily granted the default edit ClusterRole in the db-tier namespace, giving them dangerous permissions to delete or alter NetworkPolicies.

Your Tasks:

Network Isolation (Default Deny): Create a NetworkPolicy named default-deny in the db-tier namespace that drops all Ingress and Egress traffic by default.

Surgical Ingress Allow: Create a second NetworkPolicy named allow-backend in the db-tier namespace. It must allow Ingress traffic on TCP port 5432 only to pods labeled app=postgres. The source of the traffic must strictly match BOTH of these conditions simultaneously:

Originating from a namespace with the label tier=backend.

Originating from a pod with the label app=backend-api.

RBAC Lockdown:

Delete the overly permissive RoleBinding db-operator-edit in the db-tier namespace.

Create a strictly scoped Role named sts-manager in the db-tier namespace that allows the verbs get, list, watch, update, patch only on statefulsets and pods. (It must not allow modifying networkpolicies or secrets).

Create a RoleBinding named db-operator-strict tying the db-operator ServiceAccount to the sts-manager Role.