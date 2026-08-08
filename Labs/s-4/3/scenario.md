# 1. Exam Scenario

Task:
A legacy application has been deployed to the cluster in the `logging-ns` namespace. 
Currently, the application writes all of its logs to a file inside the container at `/var/log/legacy/app.log`. It does NOT write to standard output (`stdout`), meaning `kubectl logs` returns nothing.

Your task is to implement the **Sidecar Logging Pattern** so that these logs can be natively collected by the Kubernetes logging architecture.

Modify the `legacy-app` deployment to achieve the following:
1. Create a shared `emptyDir` volume to allow containers within the pod to share files.
2. Mount this volume into the existing `app-container` at `/var/log/legacy`.
3. Add a second container named `sidecar-logger` to the pod.
4. Mount the exact same volume into the `sidecar-logger` container.
5. The `sidecar-logger` container must run a command to continuously stream (`tail -f`) the contents of `/var/log/legacy/app.log` to its own `stdout`.

When fully operational:
1. The `legacy-app` deployment must have 2/2 containers running and ready.
2. Running `kubectl logs deploy/legacy-app -c sidecar-logger` must display the application logs.

# 2. Initial Cluster State

- **Namespaces:** `logging-ns`
- **Deployments:** `legacy-app` (in `logging-ns`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n logging-ns`
```text
NAME                          READY   STATUS    RESTARTS   AGE
legacy-app-6c9b5d6b49-abcde   2/2     Running   0          45s

Command: kubectl logs deploy/legacy-app -n logging-ns -c sidecar-logger | tail -n 2

Plaintext
[INFO] Application processing transaction 98...
[INFO] Application processing transaction 99...
7. Difficulty
8/10

8. Skills Tested
Multi-container Pods

Shared Volumes (emptyDir)

Kubernetes Logging Architecture (Streaming sidecar pattern)

Pod modification in place

9. Constraints
Do NOT change the image or the command of the existing app-container.

Use busybox as the image for the sidecar-logger container.

Do NOT delete the deployment and recreate it from scratch if possible, though extracting the YAML, editing, and applying is standard practice.

10. Time Estimate
10 - 15 minutes