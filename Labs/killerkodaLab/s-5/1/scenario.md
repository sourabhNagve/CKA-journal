# 1. Exam Scenario

Task:
The `finance-api` deployment in the `accounting` namespace was recently updated, but the new version is crashing. Furthermore, the autoscaling mechanism is completely broken.

You must restore the application, inject its required configurations, and fix the autoscaling architecture. 

Perform the following tasks sequentially:
1. **Rollback:** The current rollout of `finance-api` is broken. Undo the rollout to revert the deployment to its previous stable revision.
2. **Data Injection:** The stable version is running, but it lacks configuration. Modify the deployment:
   - Mount the existing Secret `db-credentials` as environment variables (`DB_USER` and `DB_PASS`).
   - Mount the existing ConfigMap `app-config` as a volume mounted at `/etc/config`.
3. **Autoscaling Prerequisites:** An existing HorizontalPodAutoscaler (HPA) named `finance-hpa` is failing to read CPU metrics (showing `<unknown>`). Fix the `finance-api` deployment by adding a CPU request of `100m` and a CPU limit of `250m` to the main container.
4. **JSONPath Extraction:** Once the HPA successfully scales the pods to its minimum requirement, write a single `kubectl` command using a JSONPath expression to extract the names of all running `finance-api` pods and output them to `/opt/finance-pods.txt`.

When fully operational:
1. The deployment must be running the previous, stable image.
2. The pods must have the Secret and ConfigMap correctly injected.
3. The HPA must show a valid CPU percentage target (not `<unknown>`).
4. `/opt/finance-pods.txt` must contain the pod names.

# 2. Initial Cluster State

- **Namespaces:** `accounting`
- **Deployments:** `finance-api` (Currently crashing)
- **Secrets:** `db-credentials` (Pre-existing)
- **ConfigMaps:** `app-config` (Pre-existing)
- **HPA:** `finance-hpa` (Pre-existing, but broken)

# 6. Expected kubectl Outputs

**Command:** `kubectl get hpa -n accounting`
```text
NAME          REFERENCE                TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
finance-hpa   Deployment/finance-api   <unknown>/50%   2         5         2          5m

(Wait 1-2 minutes after fixing resource requests for <unknown> to change to 0%/50%)

Command: cat /opt/finance-pods.txt

Plaintext
finance-api-7b89f5c4d-abcde finance-api-7b89f5c4d-fghij
7. Difficulty
9.5/10

8. Skills Tested
kubectl rollout undo

Secrets (envFrom) & ConfigMaps (volumeMounts)

Resource Requests & Limits (CPU)

Horizontal Pod Autoscaler (HPA) metrics dependencies

JSONPath formatting

9. Constraints
Do NOT delete and recreate the deployment. Modify it in place using kubectl edit or by extracting/applying YAML.

The HPA is already created; do not delete it. You must fix the deployment to satisfy the HPA's requirements.