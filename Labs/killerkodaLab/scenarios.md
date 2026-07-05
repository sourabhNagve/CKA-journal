---

# Q1

## Context

You are the security engineer for a microservices platform. The application pods in the restricted namespace need controlled outbound access to backend services.

## Question

Create a new NetworkPolicy named allow-egress-or-logic in the existing namespace restricted. The NetworkPolicy should allow outgoing (egress) traffic from Pods in namespace restricted only if all of the following conditions are met:

- Traffic is destined to Pods with label `app=database` in namespace `data` OR traffic is destined to Pods with label `role=cache` in namespace `cache`
- Traffic is directed to TCP port `5432`
- DNS must be allowed, but only to kube-dns Pods in the kube-system namespace, and only on UDP/TCP port `53`
- Pods must not be able to send traffic to any other Pods, namespaces, or external destinations
- Pods that do not send traffic on port `5432` must not be allowed egress access

<details>
<summary><strong>Q1 Solution</strong></summary>

```yaml
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
```

</details>

---

# Q2

## Context

You are working on an IoT Sensor API Platform that experiences variable traffic patterns throughout the day. The platform needs to scale automatically based on resource utilization to maintain performance while optimizing costs.

A Deployment named `sensor-api` is already running in the `iot-sys` namespace with 12 replicas. The metrics-server has been installed and configured for you.

## Question

You must configure autoscaling for this Deployment by creating an HPA called `sensor-hpa` that can scale between 2 and 8 replicas.

The HPA should use both CPU and memory utilization, with each metric targeting 80% utilization.

Adding `stabilizationWindowSeconds: 5` in the HPA ensures the replicas scale down smoothly from 12 to 2, since the 12 pods were running unnecessarily without traffic.

<details>
<summary><strong>Q2 Solution</strong></summary>

```bash
kubectl get deployments.apps -n iot-sys sensor-api
kubectl get pods -n iot-sys -l app=sensor-api
kubectl autoscale deployment -n iot-sys sensor-api --min=2 --max=8 --memory=80% --cpu=80% --dry-run=client -o yaml > hpa.yaml
```

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sensor-hpa
  namespace: iot-sys
spec:
  maxReplicas: 8
  metrics:
  - resource:
      name: cpu
      target:
        averageUtilization: 80
        type: Utilization
    type: Resource
  - resource:
      name: memory
      target:
        averageUtilization: 80
        type: Utilization
    type: Resource
  minReplicas: 2
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sensor-api
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 5
```

```bash
kubectl apply -f hpa.yaml
```

</details>

---

# Q3

## Context

U.A. High School is deploying a public Hero Registration Portal with two backend services:

- `/register` → `register-service` on port 80
- `/verify` → `verify-service` on port 80

The portal must be accessible at: `heroes.ua-academy.com`

Izuku Midoriya wants all hero data protected with TLS.

## Question

Create an Ingress named `hero-reg-ingress` in namespace `class-1a` that:

- Uses TLS termination with secret `ua-heroes-tls`
- Routes:
  - `heroes.ua-academy.com/register` → `register-service`
  - `heroes.ua-academy.com/verify` → `verify-service`
- Configure the DNS entry in `/etc/hosts` based on the Ingress LoadBalancer IP
- Test with:
  - `curl -k -v https://heroes.ua-academy.com/register | jq`
  - `curl -k -v https://heroes.ua-academy.com/verify | jq`

<details>
<summary><strong>Q3 Solution</strong></summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hero-reg-ingress
  namespace: class-1a
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - heroes.ua-academy.com
    secretName: ua-heroes-tls
  rules:
  - host: heroes.ua-academy.com
    http:
      paths:
      - path: /register
        pathType: Prefix
        backend:
          service:
            name: register-service
            port:
              number: 80
      - path: /verify
        pathType: Prefix
        backend:
          service:
            name: verify-service
            port:
              number: 80
```

```bash
kubectl apply -f hero-reg-ingress.yaml
kubectl get ingress -n class-1a
kubectl get ingress hero-reg-ingress -n class-1a
```

```bash
# Add to /etc/hosts
<INGRESS-IP> heroes.ua-academy.com
```

```bash
curl -k -v https://heroes.ua-academy.com/register | jq
curl -k -v https://heroes.ua-academy.com/verify | jq
```

</details>

---

# Q4

## Context

The Japan Railway (JR) has deployed three microservices in the `jp-bullet-train-app-prod` namespace:

- `available` - Real-time train availability
- `books` - Booking status
- `travellers` - Passenger manifest

Your task is to expose these services externally using the Kubernetes Gateway API with TLS termination and path-based routing.

Please wait 1 minute for MetalLoadBalancer to set up the gateway.

## Question

### Task 1: Create the Gateway

Create a Gateway named `bullet-train-gateway` in namespace `jp-bullet-train-gtw` with:

- `gatewayClassName: nginx`
- Protocol: HTTPS
- Port: 443
- Hostname: `bullet.train.io`
- TLS mode: `Terminate`
- TLS certificate secret: `bullet-train-tls`

### Task 2: Create the HTTPRoute

Create an HTTPRoute named `bullet-train-route` in namespace `jp-bullet-train-gtw` with:

- Parent Gateway: `bullet-train-gateway`
- Hostname: `bullet.train.io`
- `/available` → service `available` in namespace `jp-bullet-train-app-prod`
- `/books` → service `books` in namespace `jp-bullet-train-app-prod`
- `/travellers` → service `travellers` in namespace `jp-bullet-train-app-prod`

### Task 3: Configure Local DNS

Add `bullet.train.io` in `/etc/hosts` pointing to the Gateway LoadBalancer IP.

<details>
<summary><strong>Q4 Solution</strong></summary>

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bullet-train-gateway
  namespace: jp-bullet-train-gtw
spec:
  gatewayClassName: nginx
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: bullet.train.io
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: bullet-train-tls
```

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bullet-train-route
  namespace: jp-bullet-train-gtw
spec:
  parentRefs:
  - name: bullet-train-gateway
  hostnames:
  - bullet.train.io
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /available
    backendRefs:
    - name: available
      port: 80
      namespace: jp-bullet-train-app-prod
  - matches:
    - path:
        type: PathPrefix
        value: /books
    backendRefs:
    - name: books
      port: 80
      namespace: jp-bullet-train-app-prod
  - matches:
    - path:
        type: PathPrefix
        value: /travellers
    backendRefs:
    - name: travellers
      port: 80
      namespace: jp-bullet-train-app-prod
```

```bash
kubectl apply -f gateway.yaml
kubectl apply -f http.yaml
kubectl get gateway -n jp-bullet-train-gtw
kubectl get httproute -n jp-bullet-train-gtw
```

```bash
# Add to /etc/hosts
<GATEWAY-IP> bullet.train.io
```

```bash
curl -sk https://bullet.train.io/available | jq
curl -sk https://bullet.train.io/books | jq
curl -sk https://bullet.train.io/travellers | jq
```

</details>

---

# Q5

## Context

You are working on securing traffic in Kubernetes.

## Question

Create a new NetworkPolicy named `allow-port-from-namespace` in the existing namespace `fubar`.

The NetworkPolicy should allow incoming traffic to Pods in namespace `fubar` only if all of the following conditions are met:

- Traffic originates from Pods in the namespace `internal`
- Traffic is directed to TCP port `9000`
- Pods that do not listen on port `9000` must not be accessible
- Pods from namespaces other than `internal` must not be allowed access

<details>
<summary><strong>Q5 Solution</strong></summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-port-from-namespace
  namespace: fubar
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: internal
    ports:
    - protocol: TCP
      port: 9000
```

</details>

---

# Q6

## Context

You are the security engineer for a microservices platform running in Kubernetes. The security team has identified that the API service in the isolated namespace requires strict access controls.

## Question

Create a new NetworkPolicy named `allow-multi-pod-ingress` in the existing namespace `isolated`.

The NetworkPolicy should allow incoming traffic to Pods with label `app=api` in namespace `isolated` only if ALL of the following conditions are met:

- Traffic originates from Pods with label `app=frontend` and `role=proxy`
- Traffic is directed to TCP port `7000`
- Pods that do not listen on port `7000` must not be accessible
- Pods other than those with label `app=api` must not be allowed access
- Pods that do not match the above source Pod labels must not be allowed access

<details>
<summary><strong>Q6 Solution</strong></summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-multi-pod-ingress
  namespace: isolated
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
          role: proxy
    ports:
    - protocol: TCP
      port: 7000
```

</details>

---

# Q7

## Context

You are the platform engineer responsible for implementing centralized logging for your organization's applications. The web application team has deployed `web-app` in the `production` namespace, and it generates logs to `/var/log/app/app.log`.

Your task is to add a Fluentd sidecar container that will collect and forward these logs to your centralized logging infrastructure. The sidecar pattern allows you to add logging functionality without modifying the application code.

An existing Deployment named `web-app` is running in the namespace `production`.

## Question

Update the existing Deployment to add a sidecar container that follows the Fluentd sidecar logging pattern.

Requirements:

- Do not modify the existing application container
- Add a new sidecar container named `log-agent`
- The sidecar container must use the image: `fluentd:latest`
- The sidecar container must continuously read application logs from: `/var/log/app/app.log`
- Logs must be shared using a volume mounted at `/var/log/app`
- The shared volume must be mounted in both containers
- The sidecar container must remain running
- Containers must be co-located in the same Pod
- Do not create new Pods or Deployments
- Do not change existing labels, selectors, or replica counts

<details>
<summary><strong>Q7 Solution</strong></summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  template:
    spec:
      containers:
      - name: application
        image: busybox:latest
        command:
        - /bin/sh
        - -c
        - |
          mkdir -p /var/log/app
          echo "Application starting..." > /var/log/app/app.log
          while true; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] Processing request $RANDOM" >> /var/log/app/app.log
            sleep 5
          done
        volumeMounts:
        - mountPath: /var/log/app
          name: log-volume

      - name: log-agent
        image: fluentd:latest
        command:
        - sh
        - -c
        - |
          touch /var/log/app/app.log
          tail -F /var/log/app/app.log
        volumeMounts:
        - mountPath: /var/log/app
          name: log-volume

      volumes:
      - name: log-volume
        emptyDir: {}
```

</details>

---

# Q8

## Context

You are working in your company's data platform team.

Your company operates a production-grade MongoDB database on Kubernetes. The StatefulSet is named `mongodb-users-db` with 2 replicas in the `database-services` namespace.

Currently, the MongoDB pods could be scheduled on the same node, which would violate the company’s high-availability policy.

A single node failure could severely impact or completely take down the MongoDB service.

To comply with production standards, the database team requires mandatory pod anti-affinity so that MongoDB replicas MUST run on different failure domains (zones).

## Question

A StatefulSet manifest for MongoDB is stored at:

`/mongodb/mongodb-stateful.yaml`

The StatefulSet has not been applied to the cluster because it does not have PodAntiAffinity configured.

Your task:

- Update the manifest at `/mongodb/mongodb-stateful.yaml` to add required PodAntiAffinity so that:
- Ensure that no two MongoDB pods can run on the same node
- Use `requiredDuringSchedulingIgnoredDuringExecution`
- Use topologyKey: `topology.kubernetes.io/zone`
- Apply the updated manifest to create the StatefulSet with anti-affinity rules

<details>
<summary><strong>Q8 Solution</strong></summary>

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb-users-db
  namespace: database-services
spec:
  serviceName: mongodb
  replicas: 2
  selector:
    matchLabels:
      app: mongodb-users-db
  template:
    metadata:
      labels:
        app: mongodb-users-db
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - mongodb-users-db
            topologyKey: topology.kubernetes.io/zone
      containers:
      - name: mongodb
        image: mongo:5.0
        ports:
        - containerPort: 27017
          name: mongodb
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
  volumeClaimTemplates:
  - metadata:
      name: mongodb-data
    spec:
      storageClassName: local-path
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 500Mi
```

</details>

---

# Q9

## Context

You are working on integrating GitLab CI/CD with your Kubernetes cluster.

The CI/CD pipeline needs programmatic access to manage pods, deployments, and jobs across the cluster. A ServiceAccount named `gitlab-cicd-sa` has already been created in the `gitlab-cicd` namespace, and a test pod named `gitlab-cicd-nginx` is running to verify your configuration.

Your task is to set up proper RBAC permissions and generate a secure token for API authentication.

## Question

You need to configure RBAC and generate an API access token for the GitLab CI/CD integration.

Create a ClusterRole named `gitlab-cicd-role` that grants the verbs `get`, `list`, `watch`, `create`, `patch`, `delete` on the resources `pods`, `deployments`, and `jobs`.

Bind this role to the existing ServiceAccount `gitlab-cicd-sa` in the `gitlab-cicd` namespace using a ClusterRoleBinding named `gitlab-cicd-rb`.

Next, create a 2-hour valid token for the ServiceAccount. Using this token perform an HTTPS API request to list the pods in the `gitlab-cicd` namespace and store the resulting output in the file `/gitlab-cicd/pod-details.json`.

The API request should be made using the following format:

`curl --cacert ca.cert -H "Authorization: Bearer $TOKEN" https://172.30.1.2:6443/api/v1/namespaces/gitlab-cicd/pods/ > /gitlab-cicd/pod-details.json`

Do not delete or modify any existing cluster resources other than what is required for the task.

Paste the token you generated and view its details on JWT.

<details>
<summary><strong>Q9 Solution</strong></summary>

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gitlab-cicd-role
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["pods", "deployments", "jobs"]
  verbs: ["get", "list", "watch", "create", "patch", "delete"]
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: gitlab-cicd-rb
subjects:
- kind: ServiceAccount
  name: gitlab-cicd-sa
  namespace: gitlab-cicd
roleRef:
  kind: ClusterRole
  name: gitlab-cicd-role
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f rbac.yaml
kubectl create token gitlab-cicd-sa -n gitlab-cicd --duration=2h
```

</details>

---

# Q10

## Context

You are working on a Japan Tourism Platform that needs high availability across multiple deployment domains (zones).

A Deployment manifest is already stored at:

`/japan-travel-application/japan-tourism.yaml`

The Deployment has 7 replicas that need to be distributed evenly across nodes with different topology domains.

## Question

Edit the Deployment to add a topologySpreadConstraints section that satisfies the following requirements:

- Minimum required number of domains (zones) for balancing: 2
- Allowed difference between domains: 1
- Use the topology key: `traveljp.io/deployment-domain`
- Ensure the constraint balances Pods across the available nodes only when at least two domains exist
- The labelSelector must match the Pod labels:
  - `app.kubernetes.io/component: frontend`
  - `app.kubernetes.io/version: v1.0.0`
- Use `whenUnsatisfiable: DoNotSchedule` to enforce the constraint
- Do not modify replicas or any existing labels
- After editing, apply the Deployment and verify the Pod distribution

<details>
<summary><strong>Q10 Solution</strong></summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/part-of: travel-japan-platform
    team.owner: travel-platform
    workload.type: stateless
  name: travel-jp-recommender
  namespace: japan-tourism-platform
spec:
  replicas: 7
  selector:
    matchLabels:
      app.kubernetes.io/component: frontend
      app.kubernetes.io/version: v1.0.0
  strategy: {}
  template:
    metadata:
      labels:
        app.kubernetes.io/component: frontend
        app.kubernetes.io/version: v1.0.0
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          minDomains: 2
          topologyKey: traveljp.io/deployment-domain
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app.kubernetes.io/component: frontend
              app.kubernetes.io/version: v1.0.0
      containers:
      - image: public.ecr.aws/nginx/nginx:mainline-trixie
        name: backend
        ports:
        - containerPort: 80
        resources: {}
status: {}
```

</details>

---

# Q11

## Context

You are managing a Kubernetes cluster where application workloads have varying resource requirements over time. A deployment named `app-deployment` exists in the `vpa-demo` namespace with a container named `application`. Currently, the resources are manually configured, but you need to implement automatic resource optimization using Vertical Pod Autoscaler (VPA).

The VPA should monitor actual resource usage and automatically adjust both CPU and memory requests and limits, while ensuring they stay within safe operational boundaries.

## Question

Create a VerticalPodAutoscaler resource named `app-vpa` in the `vpa-demo` namespace that manages the `app-deployment` deployment.

Requirements:

- Target the deployment: `app-deployment` in namespace `vpa-demo`
- Update mode: Set to `Recreate`
- Resource policy for the container named `application`:
  - Update both CPU and memory requests AND limits
  - Minimum bounds:
    - CPU: 100m
    - Memory: 128Mi
  - Maximum bounds:
    - CPU: 2
    - Memory: 2Gi
- The VPA should control both `RequestsAndLimits` for the container

<details>
<summary><strong>Q11 Solution</strong></summary>

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
  namespace: vpa-demo
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-deployment
  updatePolicy:
    updateMode: Recreate
  resourcePolicy:
    containerPolicies:
    - containerName: application
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 2
        memory: 2Gi
      controlledResources:
      - cpu
      - memory
      controlledValues: RequestsAndLimits
```

</details>

---

# Q12

## Context

You are working as a Platform Engineer managing GPU workloads.

Your team noticed that a critical Deployment is scheduling most of its 10 replicas on a single node, causing resource imbalance. Both cluster nodes have GPU labels, but the scheduler needs guidance to prefer distributing Pods across both nodes.

## Question

A Deployment manifest is provided at:

`/app/app.yaml`

The Deployment currently schedules most of its Pods on a single node. Your cluster has two nodes:

- `controlplane`
- `node01`

Both nodes contain GPU labels:

- `gpu.vendor=nvidia`
- `gpu.count=1`

The Deployment runs 10 replicas.

Your Tasks

- Edit only the file `/app/app.yaml`
- Add NodeAffinity using `preferredDuringSchedulingIgnoredDuringExecution` so that the scheduler prefers to place Pods on nodes that have both labels:
  - `gpu.vendor = nvidia`
  - `gpu.count = 1`
- Use a weight of 50 for the preference
- Ensure the Deployment remains eligible to run its Pods across both nodes based on preferred affinity
- Do not change the number of replicas
- Apply the updated Deployment manifest

<details>
<summary><strong>Q12 Solution</strong></summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: app-flask
  name: app-flask
  namespace: app
spec:
  replicas: 10
  selector:
    matchLabels:
      app: app-flask
  strategy: {}
  template:
    metadata:
      labels:
        app: app-flask
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 50
            preference:
              matchExpressions:
              - key: gpu.count
                operator: In
                values:
                - "1"
              - key: gpu.vendor
                operator: In
                values:
                - nvidia
      containers:
      - image: public.ecr.aws/docker/library/httpd:alpine
        name: httpd
        ports:
        - containerPort: 80
```

</details>

---

# Q13

## Context

You are troubleshooting a cluster where the control plane is not healthy. On the node `controlplane`, the kube-apiserver process keeps failing to start.

Upon investigation, you discover that the static Pod manifest located under `/etc/kubernetes/manifests/kube-apiserver.yaml` contains incorrect CPU requests and limits, which exceed the node's total capacity.

As a result, the kubelet refuses to run the Pod.

## Question

Correct the manifest so that the kube-apiserver uses 20% of the node’s total CPU for both requests and limits.

<details>
<summary><strong>Q13 Solution</strong></summary>

```text
# check total cpu available with nproc or lscpu
# if total CPU is 1000m, 20% = 200m

resources:
  requests:
    cpu: 200m
  limits:
    cpu: 200m
```

```bash
crictl ps -a
```

</details>

---

# Q14

## Context

After a disaster recovery restore of a Kubernetes control plane, the kube-apiserver fails to start on the master node.

Cluster background:

- The etcd cluster is external and running in HA mode
- The disaster recovery restore process updated the kube-apiserver configuration
- kube-apiserver is currently configured to connect to etcd using port 2380
- Problem: The cluster is completely inaccessible. All kubectl commands fail with connection errors

## Question

Determine why the kube-apiserver cannot communicate with etcd.

Fix the kube-apiserver configuration so it connects to the correct etcd endpoint.

Confirm that the kube-apiserver is running and the cluster is accessible.

<details>
<summary><strong>Q14 Solution</strong></summary>

```text
# apiserver must use etcd client port 2379, not peer port 2380
# edit the kube-apiserver static pod manifest
# change the etcd endpoint from 2380 to 2379
```

```bash
crictl ps -a | grep apiserver
crictl logs <apiserver-container-id>
kubectl get nodes
```

</details>

---

# Q15

## Context

Your organization is migrating from Rancher's local-path storage to OpenEBS local storage for improved node-level volume management.

The cluster currently has a default StorageClass named `local-path`, but developers need a new OpenEBS-backed StorageClass for upcoming workloads.

You have been asked to prepare the cluster accordingly. The manifest you create must be stored at `/internal/openebs-local-sc.yaml`.

## Question

Create a new StorageClass named `openebs-local` that uses OpenEBS local provisioning with the following requirements:

- the provisioner should be `openebs.io/local`
- the volumeBindingMode should be `WaitForFirstConsumer`
- the reclaimPolicy should be `Delete`
- allowVolumeExpansion should be set to `true`
- Save the manifest at `/internal/openebs-local-sc.yaml`

After creating it, make `openebs-local` the new default StorageClass and ensure that the existing default StorageClass named `local-path` is no longer marked as default.

<details>
<summary><strong>Q15 Solution</strong></summary>

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-local
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: openebs.io/local
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

</details>

---

# Q16

## Context

You are working in your company's platform team.

Your platform team manages several mission-critical workloads in Kubernetes, including the company's customer-account MySQL database, which runs in the mysql namespace.

Earlier today, a junior engineer accidentally deleted the MySQL Deployment during routine maintenance. Fortunately, the database data is not lost — the underlying PersistentVolume (PV) still exists and is set to Retain, meaning the stored data remains intact.

Your task is to restore the MySQL Deployment and ensure that it continues to use the existing persistent data so that customer services depending on this database experience no data loss.

## Question

A PersistentVolume containing the MySQL data already exists and must be reused. A hostPath directory already created on node01 where the MySQL data is stored. (Check PV Configuration)

Create a PersistentVolumeClaim (PVC) named `mysql-pvc` in the `mysql` namespace with:

- AccessMode: ReadWriteOnce
- Storage Request: 250Mi

Update the MySQL Deployment manifest stored at:

`~/mysql-deploy.yaml`

Modify the Deployment so that it mounts the PVC you created (`mysql-pvc`) at the MySQL data directory: `/home/data`

Apply the updated Deployment to the cluster.

Validate that:

- The Deployment is running
- The Pod is bound to the existing PV via the PVC
- MySQL is stable and ready

<details>
<summary><strong>Q16 Solution</strong></summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      volumes:
      - name: shared
        persistentVolumeClaim:
          claimName: mysql-pvc
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: rootpassword123
        - name: MYSQL_DATABASE
          value: customerdb
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: shared
          mountPath: /home/data
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
  namespace: mysql
spec:
  accessModes:
  - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 250Mi
  storageClassName: ""
```

</details>

---

# Q17

## Context

Your organization, AcmeRetail, is preparing for its annual Holiday Flash Sale, a period when customer traffic increases sharply across all services.

Several engineering teams have already created custom PriorityClasses to ensure that their mission-critical microservices continue to receive scheduling preference during heavy cluster load.

A Deployment named `acme-log-forwarder`, running in the `priority` namespace, is responsible for collecting and forwarding transaction logs to the central SIEM platform during the event.

## Question

1. Identify the highest existing user-defined PriorityClass value in the cluster.
2. Create a new PriorityClass named `high-priority` whose value is one less than the highest user-defined PriorityClass.

The PriorityClass must include:

- `globalDefault: false`
- `preemptionPolicy: PreemptLowerPriority`

3. Update the Deployment `acme-log-forwarder` in the `priority` namespace so that its Pod spec uses this new PriorityClass.

<details>
<summary><strong>Q17 Solution</strong></summary>

```bash
kubectl create priorityclass high-priority --value=999999 --global-default=false --preemption-policy=PreemptLowerPriority
kubectl edit deployments.apps -n priority acme-log-forwarder
```

Add:

```yaml
spec:
  template:
    spec:
      priorityClassName: high-priority
```

</details>

---

# Q18

## Context

You are working in your company's application infrastructure team.

A `nara-frontend` Deployment is already running in the `nara` namespace with 3 replicas on the controlplane node.

Your backend team needs to ensure that backend Pods are always scheduled on the same nodes as frontend Pods for optimal performance and reduced latency.

## Question

A Deployment named `nara-frontend` is already running in the `nara` namespace with 3 replicas.

A backend Deployment manifest is stored at:

`/nara.io/nara-backend.yaml`

Update this file to add required PodAffinity so that all `nara-backend` Pods MUST be scheduled on the same node as `nara-frontend` Pods, using:

- `requiredDuringSchedulingIgnoredDuringExecution`
- `topologyKey: nara.io/zone`

After updating the manifest, apply it to create the backend Deployment.

<details>
<summary><strong>Q18 Solution</strong></summary>

```yaml
affinity:
  podAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - nara-fronted
      topologyKey: nara.io/zone
```

</details>

---