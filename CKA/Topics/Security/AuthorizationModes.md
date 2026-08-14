Authorization determines whether a user, service account, or system component has the permission to perform a specific action (verb) on a specific resource within the cluster.

⚙️ Authorization Modes
Kubernetes supports several authorization modes, which are configured in the kube-apiserver static pod manifest via the --authorization-mode flag.

Node

Purpose: Special-purpose authorizer strictly for kubelets.

Scope: Limited to node-specific operations.

Security: Restricts kubelet access so they can only read/write resources (like Pods, ConfigMaps, Secrets) tied to the specific node they are running on.

RBAC (Role-Based Access Control)

Purpose: The primary authorization mode for most Kubernetes clusters.

Scope: Controls access using Roles/RoleBindings (Namespace-scoped) and ClusterRoles/ClusterRoleBindings (Cluster-scoped).

Security: Provides fine-grained control over specific API resources and verbs (e.g., get, list, create, delete).

Webhook

Purpose: Delegates authorization decisions to an external REST service.

Scope: Highly customizable based on external policies (e.g., Open Policy Agent).

AlwaysDeny

Purpose: Denies all requests.

Use Case: Emergency lockdowns, testing, or demonstrations. Never used as the primary mode.

AlwaysAllow

Purpose: Allows all requests without checking.

Use Case: Local testing only. ⚠️ Unsafe for production as it bypasses all security checks.

🔄 The Evaluation Sequence (Why Order Matters)
When multiple modes are defined (e.g., --authorization-mode=Node,RBAC,Webhook), the sequence is critical. The API server checks the modes in the exact order they are listed.

The flow uses a "short-circuit" logic—the first mode that can decisively answer wins:

If a mode ALLOWS the request → The request is approved immediately (later modes are ignored).

If a mode DENIES the request → The request is rejected immediately.

If a mode HAS NO OPINION → Kubernetes moves to the next mode in the list.

📖 Real-World Examples
1. Node Authorizer (Kubelet Access)
Scenario A (Allow): A kubelet on node-1 requests the Pod object for a pod scheduled on node-1. The Node authorizer allows it because the resource belongs to that node.

Scenario B (Deny): The same kubelet tries to read a Secret used by a pod on node-2. The Node authorizer denies it because node-1 does not need that secret to function.

2. RBAC Authorizer (Developer Access)
Scenario A (Allow): A developer runs kubectl get pods. The Node authorizer has no opinion (since this isn't a kubelet request), so it passes to RBAC. The developer's RoleBinding permits read access, so RBAC allows it.

Scenario B (Deny): The developer tries to delete a deployment, but their Role only has get and list verbs. RBAC denies the request immediately.

3. Webhook Authorizer (Custom Policy)
Scenario: A user requests to create a pod. Neither Node nor RBAC explicitly denies it, but RBAC allows it. However, the cluster requires a Webhook to enforce a specific policy (e.g., "pods can only be created during business hours").

Result: The request is sent to the external policy service, which makes the final allow/deny decision based on the time of day.

💡 TL;DR Cheat Sheet
The Flow: First one that can answer wins.

Node: Kubelet-specific access.

RBAC: Standard access via Roles and Bindings.

Webhook: External custom policies.