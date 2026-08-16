### exam-question.md

# 1. Exam Scenario

Task:
A critical release named `app-vault` in namespace `prod-apps` failed during a recent maintenance deployment and is currently stuck in a `pending-upgrade` state.

Investigate and fix the deployment so that `app-vault` is successfully upgraded to the chart version stored at `/opt/charts/app-vault` using the production overrides in `/tmp/production-values.yaml`.

You must meet the following requirements:
1. Recover the `app-vault` release from its stuck state so that Helm operations can proceed normally.
2. Resolve any underlying RBAC or template errors causing the `pre-upgrade` database migration hook job (`app-vault-db-migrate`) to fail.
3. Successfully complete a `helm upgrade` using `/opt/charts/app-vault` and `-f /tmp/production-values.yaml`.
4. Ensure the StatefulSet managed by the release updates to 2 running and ready replicas using image `nginx:1.25.4-alpine`.
5. The final release status as reported by `helm list -n prod-apps` must be `deployed`.

# 2. Initial Cluster State

- **Namespaces**: `prod-apps`
- **Helm Releases**: `app-vault` (Status: `pending-upgrade`)
- **Chart Path**: `/opt/charts/app-vault`
- **Values Override Path**: `/tmp/production-values.yaml`
- **ConfigMaps**: `db-config` in `prod-apps`
- **RBAC**: `app-vault-hook-sa`, `app-vault-hook-role`, `app-vault-hook-rb` in `prod-apps`

# 6. Expected kubectl Outputs

**helm list -n prod-apps**
```text
NAME      	NAMESPACE	REVISION	UPDATED                                	STATUS         	CHART           	APP VERSION
app-vault 	prod-apps  	2       	2026-07-27 09:15:22.123456789 +0000 UTC	pending-upgrade	app-vault-2.4.0 	2.4.0

helm upgrade app-vault /opt/charts/app-vault -f /tmp/production-values.yaml -n prod-apps

Plaintext
Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
kubectl get pods -n prod-apps

Plaintext
NAME                    READY   STATUS   RESTARTS   AGE
app-vault-backend-0     1/1     Running  0          12m
app-vault-db-migrate-x  0/1     Error    0          2m
kubectl logs job/app-vault-db-migrate -n prod-apps

Plaintext
Checking db-config...
configmap/db-config
Updating schema...
Error from server (Forbidden): configmaps "db-config" is forbidden: User "system:serviceaccount:prod-apps:app-vault-hook-sa" cannot patch resource "configmaps" in API group "" in the namespace "prod-apps"
7. Difficulty
9/10

8. Skills Tested
Recovering stuck Helm release states (pending-upgrade handling / helm rollback or secret modification)

Debugging Helm Hooks (pre-upgrade batch jobs)

Fixing RBAC permissions required by Helm hooks

Overriding configuration with Helm values.yaml files

Helm release lifecycle and StatefulSet upgrades

9. Constraints
Do NOT delete the prod-apps namespace.

You MUST fix the issue and perform the upgrade using Helm CLI tools and chart editing.

Do NOT modify /tmp/production-values.yaml directly; fix chart templates or RBAC in the namespace/chart.

Existing ConfigMap data and PVCs must remain intact.

10. Time Estimate
15-20 minutes