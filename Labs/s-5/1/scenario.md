# 1. Exam Scenario

## Question 1: The Stubborn Volume (Strict Binding)
**Weight:** 8% | **Target Time:** 6 Minutes | **Context:** `kubectl config use-context k8s-c1-H`

**Context:**
A critical database requires a specific persistent volume on the host, but the cluster's dynamic provisioner keeps intercepting the PVC requests. 

**Task:**
1. Create a `PersistentVolume` named `db-data-pv`. It must have a capacity of `1Gi`, `ReadWriteOnce` access mode, use the `hostPath` `/mnt/data`, and have the `storageClassName` set to `manual`.
2. Create a `PersistentVolumeClaim` named `db-data-pvc` in the `storage-ns` namespace requesting `1Gi` of storage.
3. **The Trap:** You MUST ensure that `db-data-pvc` strictly binds ONLY to `db-data-pv`, regardless of any other available volumes in the cluster.
4. Create a Pod named `db-pod` in the `storage-ns` namespace using the `redis:alpine` image. Mount the PVC to the path `/data` inside the container.

---

## Question 2: The Prerequisite (InitContainers)
**Weight:** 9% | **Target Time:** 6 Minutes | **Context:** `kubectl config use-context k8s-c2-H`

**Context:**
A web server is crashing on startup because it expects a configuration file to already exist before the main process boots.

**Task:**
Create a Pod named `boot-app` in the `frontend-ns` namespace.
1. The Pod must have an `emptyDir` volume named `shared-data`.
2. **InitContainer:** Add an init container named `data-fetcher` using the `busybox` image. It must mount `shared-data` at `/work-dir`. The init container must execute the command: `sh -c "echo 'App Initialized' > /work-dir/index.html"`
3. **Main Container:** Add a main container named `web-server` using the `nginx:alpine` image. It must mount `shared-data` at `/usr/share/nginx/html`.
4. Ensure the pod transitions to the `Running` state successfully.

---

## Question 3: The Ghost Workload (Static Pods)
**Weight:** 8% | **Target Time:** 6 Minutes | **Context:** `kubectl config use-context k8s-c3-H`

**Context:**
A low-level monitoring agent needs to run directly via the kubelet on a specific worker node, completely bypassing the Kubernetes scheduler.

**Task:**
1. Identify a worker node in your cluster (a node that is NOT the control-plane). *If you are on a single-node cluster, use your primary node.*
2. SSH into that target node.
3. Deploy a **Static Pod** named `node-monitor` using the `busybox` image. 
4. The pod must run the command `sleep 1d`.
5. Ensure the static pod is registered and visible when running `kubectl get pods -A` from your control plane.

---