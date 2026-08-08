# 1. Exam Scenario

## Question 1: The Scheduling Gauntlet
**Weight:** 9% | **Target Time:** 6 Minutes | **Context:** `kubectl config use-context k8s-c1-H`

**Context:**
A machine learning deployment must run on high-performance nodes, but the target node is currently under a maintenance taint.

**Task:**
Create a Deployment named `ml-processor` in the `processing` namespace using the `nginx:alpine` image with `2` replicas.
1. The pods must ONLY be scheduled on nodes with the label `hardware=gpu`.
2. The only node in the cluster with this label has been tainted with `maintenance=active:NoSchedule`. You must configure the deployment to tolerate this exact taint so the pods can schedule.
3. Ensure both pods are in the `Running` state.

---

## Question 2: The Legacy Logger (Sidecar Pattern)
**Weight:** 9% | **Target Time:** 6 Minutes | **Context:** `kubectl config use-context k8s-c2-H`

**Context:**
A legacy application pod named `legacy-app` in the `default` namespace writes its logs to a local file instead of standard output (stdout), preventing centralized logging tools from reading it.

**Task:**
Modify the existing `legacy-app` pod to include a sidecar container.
1. Do not change or delete the existing `app` container.
2. Add a second container named `log-reader` using the `busybox` image.
3. Both containers must mount an `emptyDir` volume named `log-volume`. Mount it at `/var/log/legacy` in both containers.
4. The `log-reader` container must run the command: `/bin/sh -c "tail -f /var/log/legacy/output.log"`
*(Note: You will need to extract the existing pod manifest, delete the pod, and recreate it with the sidecar).*

---

## Question 3: The Ingress Splitter
**Weight:** 7% | **Target Time:** 6 Minutes | **Context:** `kubectl config use-context k8s-c3-H`

**Context:**
You need to route traffic to two separate backend services using a single URL endpoint.

**Task:**
Create an Ingress resource named `media-ingress` in the `media-ns` namespace.
1. The Ingress must route traffic for the host `media.company.internal`.
2. Any HTTP request to `media.company.internal/video` must route to the existing service `video-svc` on port `8080`.
3. Any HTTP request to `media.company.internal/audio` must route to the existing service `audio-svc` on port `9090`.
4. The Ingress class name must be `nginx`.

---