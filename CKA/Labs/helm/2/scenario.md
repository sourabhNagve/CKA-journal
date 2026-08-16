### exam-question.md

# 1. Exam Scenario

Task:
A Helm release named `log-processor` in the `logging` namespace was recently deployed. The application is currently failing to start and is stuck in a `CrashLoopBackOff` state because it cannot find its required configuration file. 

A junior engineer attempted to fix this by modifying the local Helm chart located at `/opt/charts/log-processor`, but when they ran `helm upgrade`, it failed with a strict Kubernetes API error regarding immutable fields. They abandoned the work and left the cluster broken.

Your task is to fix both the API errors and the runtime application errors exclusively via Helm:

1. Inspect the failing pod and identify where the configuration file should be mounted. The application strictly expects the file to be readable at `/etc/config/app.conf`.
2. Inspect the local chart at `/opt/charts/log-processor` and correct the `volumeMounts` configuration so the application can start successfully.
3. Identify and fix the misconfiguration in the local chart that is causing the `helm upgrade` to fail with an immutable field error. (Hint: The chart's selector labels were incorrectly changed).
4. Apply your fixes by successfully running a `helm upgrade`.
5. The `log-processor-0` pod must eventually reach the `Running` state.

# 2. Initial Cluster State

- **Namespaces**: `logging`
- **Helm Releases**: `log-processor` (Status: `deployed`, but pods are failing)
- **Chart Path**: `/opt/charts/log-processor`
- **StatefulSets**: `log-processor`
- **ConfigMaps**: `log-processor-config`

# 6. Expected kubectl Outputs

**kubectl get pods -n logging**
```text
NAME             READY   STATUS             RESTARTS      AGE
log-processor-0  0/1     CrashLoopBackOff   3 (20s ago)   2m

kubectl logs log-processor-0 -n logging

Plaintext
cat: can't open '/etc/config/app.conf': No such file or directory
helm upgrade log-processor /opt/charts/log-processor -n logging

Plaintext
Error: UPGRADE FAILED: cannot patch "log-processor" with kind StatefulSet: StatefulSet.apps "log-processor" is invalid: spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', 'updateStrategy', 'persistentVolumeClaimRetentionPolicy' and 'minimumReadySeconds' are forbidden
7. Difficulty
9/10

8. Skills Tested
Helm Troubleshooting & Upgrades

Resolving Kubernetes Immutable Field errors during Helm operations

Chart templating and debugging

Inspecting cluster state vs chart state (helm get manifest)

Pod Volume Mounts debugging

9. Constraints
Do NOT delete the log-processor StatefulSet manually (kubectl delete sts ...). You must perform a seamless helm upgrade that passes Kubernetes API validation.

Do NOT use kubectl edit. All changes must be made to the chart in /opt/charts/log-processor.

Do NOT delete or recreate the logging namespace.

10. Time Estimate
15-20 minutes