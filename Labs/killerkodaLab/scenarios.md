
 Q1) 
Context
You are the security engineer for a microservices platform. The application pods in the restricted namespace need controlled outbound access to backend services.

Create a new NetworkPolicy named allow-egress-or-logic in the existing namespace restricted .The NetworkPolicy should    allow outgoing (egress) traffic from Pods in namespace restricted only if all of the following conditions are met:

 - Traffic is destined to Pods with label app=database in namespace data OR traffic is destined to Pods with label       role=cache  in namespace cache
 - Traffic is directed to TCP port 5432
  - DNS must be allowed, but only to kube-dns Pods in the kube-system namespace, and only on UDP/TCP port 53
  - Pods must not be able to send traffic to any other Pods, namespaces, or external destinations
  - Pods that do not send traffic on port 5432 must not be allowed egress access

<details>
<summary>Q1 Solution</summary>

text
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-or-logic
  namespace: restricted
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: data
      podSelector:
        matchLabels:
          app: database
    - namespaceSelector:
        matchLabels:
          name: cache
      podSelector:
        matchLabels:
          role: cache
    ports:
    - protocol: TCP
      port: 5432

  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
Explanation
metadata.namespace: restricted means the NetworkPolicy is created in the restricted namespace.

podSelector: {} means the policy applies to all Pods in the restricted namespace.

policyTypes: [Egress] means only outbound traffic is controlled.

The first egress rule allows traffic only to:

Pods with label app=database in namespace data, or

Pods with label role=cache in namespace cache,

and only on TCP port 5432.

The second egress rule allows DNS traffic only to kube-dns Pods in the kube-system namespace on port 53 using both TCP and UDP.

Because no other egress rules are defined, all other outbound traffic is denied.

</details>


Q2) Context
You are working 🧑‍💻 on an IoT Sensor API Platform that experiences variable traffic patterns throughout the day. The platform needs to scale automatically based on resource utilization to maintain performance while optimizing costs.

A Deployment named sensor-api is already running in the iot-sys namespace with 12 replicas. The metrics-server has been installed and configured for you.

❓ Question
A Deployment named sensor-api is running in the iot-sys namespace.

You must configure autoscaling for this Deployment by creating an HPA called sensor-hpa that can scale between 2 and 8 replicas.

The HPA should use both CPU and memory utilization, with each metric targeting 80% utilization.

Adding stabilizationWindowSeconds: 5 in the HPA ensures the replicas scale down smoothly from 12 to 2 , since the 12 pods were running unnecessarily without traffic.

Q3)📖 Problem Statement
U.A. High School is deploying a public Hero Registration Portal with two backend services:

/register → register-service on port 80
/verify → verify-service on port 80
The portal must be accessible at: heroes.ua-academy.com

Izuku Midoriya wants all hero data protected with TLS.

Task:

Create an Ingress named hero-reg-ingress in namespace class-1a that:

Uses TLS termination with secret ua-heroes-tls
Routes:
heroes.ua-academy.com/register → register-service
heroes.ua-academy.com/verify → verify-service
Configure the DNS entry in /etc/hosts based on the Ingress LoadBalancer IP
curl -k -v https://heroes.ua-academy.com/register | jq
curl -k -v https://heroes.ua-academy.com/verify | jq

  

Q4)   The Japan Railway (JR) has deployed three microservices in the jp-bullet-train-app-prod namespace:

available - Real-time train availability
books - Booking status
travellers - Passenger manifest
Your task is to expose these services externally using the Kubernetes Gateway API with TLS termination and path-based routing.

Please wait 1 minute for MetalLoadBalancer to set up the gateway.
🎯 Your Tasks:
Task 1: Create the Gateway
Create a Gateway named bullet-train-gateway in namespace jp-bullet-train-gtw with the following specifications:

Name: bullet-train-gateway
Namespace: jp-bullet-train-gtw
GatewayClassName: nginx
Listener Configuration:
Protocol: HTTPS
Port: 443
Hostname: bullet.train.io
TLS Mode: Terminate
TLS Certificate: Reference the existing Secret bullet-train-tls in the same namespace
Note: The TLS secret bullet-train-tls has already been created in the jp-bullet-train-gtw namespace.

Task 2: Create the HTTPRoute
Create an HTTPRoute named bullet-train-route in namespace jp-bullet-train-gtw with path-based routing:

Name: bullet-train-route
Namespace: jp-bullet-train-gtw
Parent Gateway: bullet-train-gateway
Hostname: bullet.train.io
Routes:
Path /available → Service available (port 80) in namespace jp-bullet-train-app-prod
Path /books → Service books (port 80) in namespace jp-bullet-train-app-prod
Path /travellers → Service travellers (port 80) in namespace jp-bullet-train-app-prod
Path Match Type: PathPrefix for all routes
Task 3: Configure Local DNS
To access the services via the domain name bullet.train.io :

Edit the /etc/hosts file
Add an entry mapping bullet.train.io to the Gateway's LoadBalancer IP
Test access to all three endpoints using curl with the -k flag (to skip certificate verification for self-signed cert)
Task 4: Validation Test
Tests all three endpoints:

#!/bin/bash
echo "Testing Available Trains:"
curl -sk https://bullet.train.io/available | jq

echo -e "\nTesting Bookings:"
curl -sk https://bullet.train.io/books | jq

echo -e "\nTesting Travellers:"
curl -sk https://bullet.train.io/travellers | jq



Q5)------------------------------------------------
🔒 CKA - Configure NetworkPolicy
📘 Official Kubernetes Documentation — NetworkPolicy
NetworkPolicy Concept

📖 Problem Statement
Create a new NetworkPolicy named allow-port-from-namespace in the existing namespace fubar .

The NetworkPolicy should allow incoming traffic to Pods in namespace fubar only if all of the following conditions are met:

Traffic originates from Pods in the namespace internal
Traffic is directed to TCP port 9000
Pods that do not listen on port 9000 must not be accessible
Pods from namespaces other than internal must not be allowed access


Q6) -----------------------------------------------------
🏢 Context
You are the security engineer for a microservices platform running in Kubernetes. The security team has identified that the API service in the isolated namespace requires strict access controls.

❓ Problem Statement
Create a new NetworkPolicy named allow-multi-pod-ingress in the existing namespace isolated .

The NetworkPolicy should allow incoming traffic to Pods with label app=api in namespace isolated only if ALL of the following conditions are met:

Traffic originates from Pods with label app=frontend & role=proxy
Traffic is directed to TCP port 7000
Pods that do not listen on port 7000 must not be accessible
Pods other than those with label app=api must not be allowed access
Pods that do not match the above source Pod labels must not be allowed access


Q6) ------------------------------------------------------------
🏢 Context
You are the platform engineer responsible for implementing centralized logging for your organization's applications. The web application team has deployed web-app in the production namespace, and it generates logs to /var/log/app/app.log .

Your task is to add a Fluentd sidecar container that will collect and forward these logs to your centralized logging infrastructure. The sidecar pattern allows you to add logging functionality without modifying the application code.

An existing Deployment named web-app is running in the namespace production .

❓ Problem Statement
Task: Update the existing Deployment to add a sidecar container that follows the Fluentd sidecar logging pattern.

Requirements:

Do not modify the existing application container
Add a new sidecar container named log-agent
The sidecar container must use the image: fluentd:latest
The sidecar container must continuously read application logs from: /var/log/app/app.log
Logs must be shared using a volume mounted at /var/log/app
The shared volume must be mounted in both containers
The sidecar container must remain running
Containers must be co-located in the same Pod
Do not create new Pods or Deployments
Do not change existing labels, selectors, or replica counts


Q8) -------------------------------------------------------
🏢 Context
You are working 🧑‍💻 in your company's data platform team.

Your company operates a production-grade MongoDB database on Kubernetes. The StatefulSet is named mongodb-users-db with 2 replicas in the database-services namespace.

Currently, the MongoDB pods could be scheduled on the same node, which would violate the company’s high-availability policy.

A single node failure could severely impact or completely take down the MongoDB service.

To comply with production standards, the database team requires mandatory pod anti-affinity so that MongoDB replicas MUST run on different failure domains (zones).

❓ Question
A StatefulSet manifest for MongoDB is stored at:

/mongodb/mongodb-stateful.yaml
The StatefulSet has not been applied to the cluster because it does not have PodAntiAffinity configured.

Your task:

Update the manifest at /mongodb/mongodb-stateful.yaml to add required PodAntiAffinity so that:

Ensure that no two MongoDB pods can run on the same node
Use requiredDuringSchedulingIgnoredDuringExecution
Use topologyKey: topology.kubernetes.io/zone
Apply the updated manifest to create the StatefulSet with anti-affinity rules

Q9) -------------------------------------------------------
 CKA: RBAC and ServiceAccount Token Management
📚 Official Kubernetes Documentation:

Using RBAC Authorization
Managing Service Accounts
Kubernetes API Access
JSON Web Tokens (JWT)
🏢 Context
You are working 🧑‍💻 on integrating GitLab CI/CD with your Kubernetes cluster.

The CI/CD pipeline needs programmatic access to manage pods, deployments, and jobs across the cluster. A ServiceAccount named gitlab-cicd-sa has already been created in the gitlab-cicd namespace, and a test pod named gitlab-cicd-nginx is running to verify your configuration.

Your task is to set up proper RBAC permissions and generate a secure token for API authentication.

❓ Question
You need to configure RBAC and generate an API access token for the GitLab CI/CD integration.

Create a ClusterRole named gitlab-cicd-role that grants the verbs get , list , watch , create , patch , delete on the resources pods , deployments , and jobs .

Bind this role to the existing ServiceAccount gitlab-cicd-sa in the gitlab-cicd namespace using a ClusterRoleBinding named gitlab-cicd-rb .

Next, create a 2-hour valid token for the ServiceAccount.Using this token perform an HTTPS API request to list the pods in the gitlab-cicd namespace and store the resulting output in the file /gitlab-cicd/pod-details.json .

The API request should be made using the following format:

curl --cacert ca.cert -H "Authorization: Bearer $TOKEN"  https://172.30.1.2:6443/api/v1/namespaces/gitlab-cicd/pods/ > /gitlab-cicd/pod-details.json
Do not delete or modify any existing cluster resources other than what is required for the task.

Paste the token you generated and view its details on JWT.


Q10)------------------------------------------------------
🧠 CKA: TopologySpreadConstraints
📚 Official Kubernetes Documentation: Kubernetes Documentation - Pod Topology Spread Constraints

🏢 Context
You are working 🧑‍💻 on a Japan Tourism Platform that needs high availability across multiple deployment domains (zones).

A Deployment manifest is already stored at:

/japan-travel-application/japan-tourism.yaml
The Deployment has 7 replicas that need to be distributed evenly across nodes with different topology domains.

❓ Question
Edit the Deployment to add a topologySpreadConstraints section that satisfies the following requirements:

Minimum required number of domains (zones) for balancing: 2
Allowed difference between domains: 1
Use the topology key: traveljp.io/deployment-domain
Ensure the constraint balances Pods across the available nodes only when at least two domains exist
The labelSelector must match the Pod labels:
app.kubernetes.io/component: frontend
app.kubernetes.io/version: v1.0.0
Use whenUnsatisfiable: DoNotSchedule to enforce the constraint
Do not modify replicas or any existing labels
After editing, apply the Deployment and verify the Pod distribution.


Q11-------------------------------------------------------

🎯 Context
You are managing a Kubernetes cluster where application workloads have varying resource requirements over time. A deployment named app-deployment exists in the vpa-demo namespace with a container named application . Currently, the resources are manually configured, but you need to implement automatic resource optimization using Vertical Pod Autoscaler (VPA).

The VPA should monitor actual resource usage and automatically adjust both CPU and memory requests and limits, while ensuring they stay within safe operational boundaries.

❓ Task
Create a VerticalPodAutoscaler resource named app-vpa in the vpa-demo namespace that manages the app-deployment deployment.

Requirements:

Target the deployment: app-deployment in namespace vpa-demo

Update mode: Set to Recreate

Resource policy for the container named application :

Update both CPU and memory requests AND limits
Minimum bounds:
CPU: 100m
Memory: 128Mi
Maximum bounds:
CPU: 2 (2 cores)
Memory: 2Gi
The VPA should control both RequestsAndLimits for the container

Q12)------------------------------------------------------
🏢 Context
You are working 🧑‍💻 as a Platform Engineer managing GPU workloads.
Your team noticed that a critical Deployment is scheduling most of its 10 replicas on a single node, causing resource imbalance. Both cluster nodes have GPU labels, but the scheduler needs guidance to prefer distributing Pods across both nodes.

❓ Question
A Deployment manifest is provided at:

/app/app.yaml
The Deployment currently schedules most of its Pods on a single node. Your cluster has two nodes:

controlplane
node01
Both nodes contain GPU labels:

gpu.vendor=nvidia
gpu.count=1
The Deployment runs 10 replicas.

Your Tasks
Edit only the file /app/app.yaml .
Add NodeAffinity using preferredDuringSchedulingIgnoredDuringExecution so that the scheduler prefers to place Pods on nodes that have both labels:
gpu.vendor = nvidia
gpu.count = 1
Use a weight of 50 for the preference.
Ensure the Deployment remains eligible to run its Pods across both nodes based on preferred affinity.
Do not change the number of replicas.
Apply the updated Deployment manifest.

Q13)------------------------------------------------------
🧠 CKA: Troubleshoot kube-apiserver Static Pod CPU Resources
📚 Official Kubernetes Documentation:

Static Pods
Managing Resources for Containers
Configure Quality of Service for Pods
You are troubleshooting a cluster where the control plane is not healthy. On the node controlplane, the kube-apiserver process keeps failing to start.

Upon investigation, you discover that the static Pod manifest located under /etc/kubernetes/manifests/kube-apiserver.yaml contains incorrect CPU requests and limits, which exceed the node's total capacity.

As a result, the kubelet refuses to run the Pod.

Your task is to correct the manifest so that the kube-apiserver uses 20% of the node’s total CPU for both requests and limits .

Q14)------------------------------------------------------
CKA: Troubleshoot kube-apiserver etcd Connection
📚 Official Kubernetes Documentation:

Operating etcd clusters
kube-apiserver Configuration
Static Pods
Troubleshooting Clusters
🎯 Scenario
After a disaster recovery restore of a Kubernetes control plane, the kube-apiserver fails to start on the master node.

Cluster background:

The etcd cluster is external and running in HA mode
The disaster recovery restore process updated the kube-apiserver configuration
kube-apiserver is currently configured to connect to etcd using port 2380
Problem: The cluster is completely inaccessible. All kubectl commands fail with connection errors.

❓ Task
Determine why the kube-apiserver cannot communicate with etcd
Fix the kube-apiserver configuration so it connects to the correct etcd endpoint
Confirm that the kube-apiserver is running and the cluster is accessible

Q15)-----------------------------------------------------
🧠 CKA: Storage Migration for Local Volumes
📚 Official Kubernetes Documentation:

Storage Classes
Volume Binding Mode
Change Default StorageClass
🏢 Context
Your organization is migrating from Rancher's local-path storage to OpenEBS local storage for improved node-level volume management.

The cluster currently has a default StorageClass named local-path , but developers need a new OpenEBS-backed StorageClass for upcoming workloads.

You have been asked to prepare the cluster accordingly. The manifest you create must be stored at /internal/openebs-local-sc.yaml .

❓ Question
Create a new StorageClass named openebs-local that uses OpenEBS local provisioning with the following requirements:

the provisioner should be openebs.io/local , the volumeBindingMode should be WaitForFirstConsumer
the reclaimPolicy should be Delete
allowVolumeExpansion should be set to true . Save the manifest at /internal/openebs-local-sc.yaml .
After creating it, make openebs-local the new default StorageClass and ensure that the existing default StorageClass named local-path is no longer marked as default.

Q16)-----------------------------------------------------
🧠 CKA: Restore MySQL with Persistent Data
📚 Kubernetes PersistentVolumes Documentation

📚 Kubernetes Storage Classes Documentation

🏢 Context
You are working 🧑‍💻 in your company's platform team.

Your platform team manages several mission-critical workloads in Kubernetes, including the company's customer-account MySQL database, which runs in the mysql namespace.

Earlier today, a junior engineer accidentally deleted the MySQL Deployment during routine maintenance. Fortunately, the database data is not lost — the underlying PersistentVolume (PV) still exists and is set to Retain, meaning the stored data remains intact.

Your task is to restore the MySQL Deployment and ensure that it continues to use the existing persistent data so that customer services depending on this database experience no data loss.

❓ Task
A PersistentVolume containing the MySQL data already exists and must be reused.A hostPath directory already created on node01 where the MySQL data is stored. (Check PV Configuration)

Create a PersistentVolumeClaim (PVC) named mysql-pvc in the mysql namespace with:

AccessMode: ReadWriteOnce
Storage Request: 250Mi
Update the MySQL Deployment manifest stored at:

~/mysql-deploy.yaml
Modify the Deployment so that it mounts the PVC you created (mysql-pvc ) at the MySQL data directory: /home/data

Apply the updated Deployment to the cluster.

Validate that:

The Deployment is running
The Pod is bound to the existing PV via the PVC
MySQL is stable and ready


Q17)-----------------------------------------------------
🛒 CKA Exam Question - PriorityClass Configuration
📚 Additional Resources
Kubernetes Pod Priority
PriorityClass API Reference
Scheduling Best Practices
📖 Real-Life Context
Your organization, AcmeRetail, is preparing for its annual Holiday Flash Sale, a period when customer traffic increases sharply across all services.

Several engineering teams have already created custom PriorityClasses to ensure that their mission-critical microservices continue to receive scheduling preference during heavy cluster load.

A Deployment named acme-log-forwarder , running in the priority namespace, is responsible for collecting and forwarding transaction logs to the central SIEM platform during the event.

🎯 Your Task
1. Identify the highest existing user-defined PriorityClass value in the cluster.

2. Create a new PriorityClass named high-priority whose value is one less than the highest user-defined PriorityClass.
The PriorityClass must include:

globalDefault: false
preemptionPolicy: PreemptLowerPriority
3. Update the Deployment acme-log-forwarder in the priority namespace so that its Pod spec uses this new PriorityClass.


Q18)-----------------------------------------------------
🧠 CKA: PodAffinity - Backend Near Frontend
📚 Kubernetes PodAffinity Documentation

🏢 Context
You are working 🧑‍💻 in your company's application infrastructure team.
A nara-frontend Deployment is already running in the nara namespace with 3 replicas on the controlplane node.

Your backend team needs to ensure that backend Pods are always scheduled on the same nodes as frontend Pods for optimal performance and reduced latency.

❓ Question
A Deployment named nara-frontend is already running in the nara namespace with 3 replicas.

A backend Deployment manifest is stored at:

/nara.io/nara-backend.yaml
Update this file to add required PodAffinity so that all nara-backend Pods MUST be scheduled on the same node as nara-frontend Pods, using:

requiredDuringSchedulingIgnoredDuringExecution
topologyKey: nara.io/zone
After updating the manifest, apply it to create the backend Deployment.

Q19)-----------------------------------------------------
Q20)------------------------------------------------------
🧮 Configure Pod Resource Management for Python ML Application
📚 Official Kubernetes Documentation: Managing Resources for Containers

You are managing a Python Machine Learning web application running in a Kubernetes cluster. The application is currently deployed without proper resource configuration, which could lead to instability and resource contention.

🎯 Your Tasks:
Task 1: Scale Down the Deployment
Scale down the python-webapp deployment in the python-ml-ns namespace to 0 replicas to safely make configuration changes.

Task 2: Calculate Resource Allocation
Important: Before editing the deployment, you need to calculate the correct resource values.

Requirements:

The deployment will run 3 pods
Resources must be divided evenly across all 3 pods
Add 20% overhead to avoid node instability (reserve 20% for system processes)
Both init containers and main containers must have identical resource requests and limits.
Task 3: Edit the Deployment
Edit the python-webapp deployment and add resource requests and limits to both the init container (init-setup ) and the main container (python-app ).

After successfully editing the deployment, scale it back to 3 replicas.

Verify that all 3 pods are in Running state and have the correct resource configuration:

Q21)------------------------------------------------------
🧠 CKA: PersistentVolumeClaim with Dynamic Provisioning
📚 Official Kubernetes Documentation:

Persistent Volumes
Storage Classes
Configure a Pod to Use a PersistentVolumeClaim
Dynamic Volume Provisioning
🔧 Context
You are working 🧑‍💻 on preparing a workload that performs local image processing for your company. The operations namespace already exists, and a Deployment manifest for the application has been created at /src/k8s/image-processor.yaml .

This Deployment is functional but currently does not include any persistent storage. The application needs a cache directory at /cache to store temporary processing results that should persist across pod restarts.

The cluster uses the Rancher Local Path Provisioner with a StorageClass named local-path , which supports dynamic provisioning of local storage on the worker nodes.

❓ Task
Complete the following tasks to add persistent storage to the image processor application:

Create a PersistentVolumeClaim named processor-cache in the operations namespace that:

Request 1Gi of storage with ReadWriteOnce access.
Uses the local-path StorageClass
Is dynamically provisioned (no manual PV creation needed)
Modify the existing Deployment manifest at /src/k8s/image-processor.yaml :

Add a volume that references the PVC processor-cache ; the volume name should be cache-storage .
Add a volumeMount to mount the PVC at /cache inside the container
Do not change any other part of the Deployment
Apply your changes and verify:

The PVC becomes Bound
A dynamically provisioned PV is created automatically
The running pod mounts the volume at /cache
You can create and read a file inside /cache from the pod

Q22)-----------------------------------------------------
Q23-------------------------------------------------------
Q24)------------------------------------------------------
Q25)------------------------------------------------------
Q26)------------------------------------------------------
Q27)------------------------------------------------------
Q28)------------------------------------------------------
Q29)------------------------------------------------------
Q30)------------------------------------------------------
Q31) -------------------------------------------------------