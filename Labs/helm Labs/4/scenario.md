### exam-question.md

# 1. Exam Scenario

Task:
A release named `web-store` in the `e-commerce` namespace is currently in a `failed` state following an unsuccessful upgrade attempt by a junior engineer.

Investigate the failure and successfully upgrade the release to the chart located at `/opt/charts/web-store`.

You must resolve the following issues exclusively using Helm and Kubernetes CLI tools:
1. Identify and resolve the issue with the `pre-upgrade` hook Job that is currently stuck and preventing any new `helm upgrade` attempts.
2. Correct the invalid image tag in `/opt/charts/web-store/values.yaml` for the migration job so it can run successfully.
3. A misconfiguration in `/opt/charts/web-store/values.yaml` violates Kubernetes StatefulSet immutability rules. Identify this configuration and revert it to match the cluster's current state so the upgrade can proceed.
4. Successfully run a `helm upgrade` using the local chart.
5. The `web-store` release must reach a `deployed` status, and the `web-store-0` pod must be `Running`.

# 2. Initial Cluster State

- **Namespaces**: `e-commerce`
- **Helm Releases**: `web-store` (Status: `failed`)
- **StatefulSets**: `web-store`
- **Jobs**: `web-store-db-migration` (Failing / stuck)
- **Chart Path**: `/opt/charts/web-store`

# 6. Expected kubectl Outputs

**helm ls -n e-commerce**
```text
NAME       	NAMESPACE 	REVISION	UPDATED                                	STATUS	CHART          	APP VERSION
web-store  	e-commerce	2       	2026-07-27 16:55:10.123456789 +0530 IST	failed	web-store-2.0.0

kubectl get pods -n e-commerce

Plaintext
NAME                               READY   STATUS             RESTARTS   AGE
web-store-0                        1/1     Running            0          10m
web-store-db-migration-xxxxx       0/1     ImagePullBackOff   0          2m
helm upgrade web-store /opt/charts/web-store -n e-commerce

Plaintext
Error: UPGRADE FAILED: job "web-store-db-migration" already exists
(After fixing the Job) helm upgrade web-store /opt/charts/web-store -n e-commerce

Plaintext
Error: UPGRADE FAILED: cannot patch "web-store" with kind StatefulSet: StatefulSet.apps "web-store" is invalid: spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', 'updateStrategy', 'persistentVolumeClaimRetentionPolicy' and 'minimumReadySeconds' are forbidden
7. Difficulty
9/10

8. Skills Tested
Helm Pre-Upgrade Hooks lifecycle

Recovering failed Helm releases

Resolving Kubernetes Immutable Field conflicts during Helm upgrades

Debugging Helm values.yaml

9. Constraints
Do NOT delete the web-store StatefulSet manually (kubectl delete sts ...). You must perform a seamless helm upgrade.

You may delete the failed hook Job manually OR add a Helm hook-delete-policy to the chart.

You must make all configuration corrections directly in /opt/charts/web-store/values.yaml.

10. Time Estimate
15-20 minutes