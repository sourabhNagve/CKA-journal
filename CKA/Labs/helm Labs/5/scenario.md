### exam-question.md

# 1. Exam Scenario

Task:
You are tasked with upgrading the `dash-frontend` Helm release in the `monitoring` namespace to version `2.0.0`. The new chart is located on the controlplane node at `/opt/charts/dash-frontend`.

During the upgrade attempt, you will encounter multiple failures. You must troubleshoot and resolve these issues to successfully complete the deployment.

Requirements:
1. The new chart relies on a local subchart dependency that is currently missing from the release's `charts/` directory. You must resolve this dependency requirement.
2. The upgrade will conflict with an existing, manually created ConfigMap named `dash-frontend-config`. You must bring this ConfigMap under Helm's management WITHOUT deleting it or its data.
3. The new chart introduces a templating type error that causes the Kubernetes API to reject the Deployment manifest. You must identify the invalid field (a port number passed as an integer instead of a string in an environment variable) and correct the local chart so the upgrade can proceed.
4. Apply your fixes and successfully execute the `helm upgrade`.
5. Ensure the `dash-frontend` pod and its dependency pod both successfully start and reach the `Running` state.

# 2. Initial Cluster State

- **Namespaces**: `monitoring`
- **Helm Releases**: `dash-frontend` (Revision 1)
- **Chart Paths**: 
  - `/opt/charts/dash-frontend` (Target v2.0.0 chart)
  - `/opt/charts/redis-cache` (Local dependency chart)
- **ConfigMaps**: `dash-frontend-config` (Unmanaged, causing conflicts)
- **Deployments**: `dash-frontend`

# 6. Expected kubectl Outputs

**helm upgrade dash-frontend /opt/charts/dash-frontend -n monitoring**
```text
Error: UPGRADE FAILED: found in Chart.yaml, but missing in charts/ directory: redis-cache

(After fixing dependency): helm upgrade dash-frontend /opt/charts/dash-frontend -n monitoring

Plaintext
Error: UPGRADE FAILED: rendered manifests contain a resource that already exists. Unable to continue with install: ConfigMap "dash-frontend-config" in namespace "monitoring" exists and cannot be imported into the current release: invalid ownership metadata; annotation validation error: missing key "meta.helm.sh/release-name": must be set to "dash-frontend"; annotation validation error: missing key "meta.helm.sh/release-namespace": must be set to "monitoring"
(After fixing adoption): helm upgrade dash-frontend /opt/charts/dash-frontend -n monitoring

Plaintext
Error: UPGRADE FAILED: cannot patch "dash-frontend" with kind Deployment: Deployment.apps "dash-frontend" is invalid: spec.template.spec.containers[0].env[0].value: Invalid value: 8080: must be a string
7. Difficulty
9/10

8. Skills Tested
Helm Chart Dependencies (helm dependency update)

Adopting unmanaged resources into a Helm release

Debugging Kubernetes API validation errors caused by Helm templating (Integers vs Strings)

Chart templating functions (quote) or values.yaml type overrides

Helm Upgrades

9. Constraints
Do NOT delete or recreate the dash-frontend-config ConfigMap. You must adopt it using standard Helm annotations/labels.

Do NOT use kubectl edit on the Deployment. Fix the chart at /opt/charts/dash-frontend and use helm upgrade.

Do NOT delete the monitoring namespace.

10. Time Estimate
15-20 minutes