### exam-question.md

# 1. Exam Scenario

Task:
A critical release named `data-pipeline` in the `etl-prod` namespace needs to be upgraded to version 2.0.0. The new chart version introduces a required `api-token` Secret and a new NetworkPolicy to allow egress to a Redis cache. 

However, a previous engineer attempted the `helm upgrade` and failed. They abandoned the work, leaving the new chart files at `/opt/charts/data-pipeline`.

You must successfully complete the upgrade and ensure the application becomes fully functional.

Requirements:
1. Attempting to upgrade currently fails with an error stating that the `api-token` Secret already exists and cannot be imported. You must bring the existing unmanaged Secret under Helm's management WITHOUT deleting it.
2. The upgraded pods will fail to initialize. Investigate the `initContainer` failure. 
3. Identify and fix a misconfiguration in the chart's NetworkPolicy template (`/opt/charts/data-pipeline/templates/networkpolicy.yaml`) that is causing the initialization failure.
4. Successfully apply the fixes via `helm upgrade`.
5. The `data-pipeline` pods must successfully reach the `Running` state.

# 2. Initial Cluster State

- **Namespaces**: `etl-prod`
- **Helm Releases**: `data-pipeline` (Currently at Revision 1)
- **Chart Path**: `/opt/charts/data-pipeline` (Contains v2.0.0 with bugs)
- **Deployments**: `data-pipeline`, `data-pipeline-redis`
- **Secrets**: `api-token` (Unmanaged, causing conflicts)
- **NetworkPolicies**: `default-deny-egress` (Existing, must not be removed)

# 6. Expected kubectl Outputs

**helm upgrade data-pipeline /opt/charts/data-pipeline -n etl-prod**
```text
Error: UPGRADE FAILED: rendered manifests contain a resource that already exists. Unable to continue with install: Secret "api-token" in namespace "etl-prod" exists and cannot be imported into the current release: invalid ownership metadata; annotation validation error: missing key "meta.helm.sh/release-name": must be set to "data-pipeline"; annotation validation error: missing key "meta.helm.sh/release-namespace": must be set to "etl-prod".

(After fixing the Secret adoption): kubectl get pods -n etl-prod

Plaintext
NAME                             READY   STATUS                  RESTARTS      AGE
data-pipeline-8566b9449f-b7wkl   0/1     Init:CrashLoopBackOff   3 (20s ago)   2m
data-pipeline-redis-0            1/1     Running                 0             10m
(After fixing the Chart and Upgrading): kubectl get pods -n etl-prod

Plaintext
NAME                             READY   STATUS    RESTARTS   AGE
data-pipeline-7c55894b9f-x9pq2   1/1     Running   0          45s
data-pipeline-redis-0            1/1     Running   0          15m
7. Difficulty
9/10

8. Skills Tested
Helm Resource Adoption (meta.helm.sh annotations / labels)

Resolving Helm "Resource already exists" conflicts

Chart templating and debugging

NetworkPolicies and Pod Selectors

Troubleshooting InitContainers and egress connectivity

Helm Upgrades

9. Constraints
Do NOT delete or recreate the api-token Secret. You must adopt it.

Do NOT delete or modify the existing default-deny-egress NetworkPolicy.

Do NOT use kubectl edit on the Deployment or NetworkPolicy. You MUST fix the Helm chart and use helm upgrade.

10. Time Estimate
15-20 minutes