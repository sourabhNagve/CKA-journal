SRE INCIDENT REPORT: INC-8442 (The Scenario)
Priority: P0 - SEV 1
Component: Control Plane (eu-central-1-prod)
Status: API Server OFFLINE (Quorum Lost)

Context:
At 04:00 UTC, a rogue mutating admission webhook introduced a recursive loop into the control plane, causing a massive memory leak in etcd. The API servers have OOM-killed, and the control plane is entirely unresponsive. We cannot rely on kubectl to query the cluster state.

The incident response team has managed to mount the raw disk volumes of the control plane nodes and extracted offline JSON dumps of the etcd state, node registries, and API audit logs.

Your Objective:
You must parse the raw JSON data and logs to extract critical recovery tokens, identify the blast radius, and map the rogue workloads so we can manually patch the underlying data store. You must rely solely on native Linux text-processing tools (jq, sed, awk, grep, bash).

Do not guess. One malformed configuration during the manual restore will corrupt the cluster permanently. Save the output of each task to its corresponding answer file (q1.txt through q5.txt).

THE TASKS (Offline Data Parsing)
Task 1: The Break-Glass Token
The automated deployment pipeline relies on a secret to bypass the webhook lock. You have the raw etcd-dump.json.
Find the Secret object that meets both conditions:

type is exactly "Opaque".

Has a label where criticality equals "tier-0".

Extract the token field from the data block, decode it from base64, and save the plain-text string to q1.txt.

Task 2: Escaped Keys and Deep Traversal
The node states are captured in nodes.json. The rogue webhook caused some nodes to panic and taint themselves.
Find the exact name of the node that possesses a taint with the key node.kubernetes.io/memory-pressure and the effect NoSchedule.
Warning: Many nodes have missing taint arrays entirely. Your query must handle null iterations without throwing errors.
Save the exact node name to q2.txt.

Task 3: Anomalous Log Extraction
We need the IP addresses of the compromised service accounts. You have a corrupted audit.log containing mixed data, extra spaces, and inconsistent formatting.
Extract all IP addresses that made a PATCH request which resulted in an HTTP 429 status code.
Format the output as a list of unique, deduplicated IP addresses, one per line, sorted in ascending order. Save to q3.txt.

Task 4: Relational Column Mapping
We need to map failing containers without kubectl get pods -o custom-columns. You have pods.json.
Target the kube-system namespace. Find any pod where a container has a restartCount strictly greater than 50 AND its image string contains v1.22.
Format your output exactly as PodName:ContainerName:RestartCount. Save to q4.txt.

Task 5: The Null-Reference Trap
The webhook targeted deployments with misconfigured resource limits. In deployments.json, find the names of all Deployments where at least one container has resources.limits.cpu defined, but resources.requests.cpu is completely missing (or null).
Warning: Some containers have no resources block at all. Your query must safely navigate missing intermediate keys.
Save the deployment name(s) to q5.txt.