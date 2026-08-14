# 1. Exam Scenario

Task:
A CronJob named `db-backup` exists in the `db-ops` namespace. It is responsible for taking scheduled backups of a PostgreSQL database running in the `finance-system` namespace. 

Currently, no backups are being generated. The operations team has reported multiple failures preventing the CronJob from executing successfully.

Troubleshoot and resolve all issues so that the `db-backup` CronJob successfully executes and completes its backup script.

# 2. Initial Cluster State

- **Namespaces:** `db-ops`, `finance-system`
- **Pods:** `postgres-db` (in `finance-system`)
- **CronJobs:** `db-backup` (in `db-ops`)
- **PVCs:** `backup-pvc` (in `db-ops`, currently `Pending`)
- **ServiceAccounts:** `backup-sa` (in `db-ops`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get cronjobs -n db-ops`
```text
NAME        SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
db-backup   * * * * * True      0        <none>          15m


8. Skills Tested
CronJobs & Job Management

Cross-Namespace RBAC (Roles & RoleBindings)

Storage (StorageClasses, PersistentVolumes, PersistentVolumeClaims)

Troubleshooting multi-layered deployment dependencies

9. Constraints
Do NOT delete or recreate the backup-pvc PVC. It must remain and transition to Bound.

Do NOT modify the image or the command specified inside the db-backup CronJob.

Ensure the backup-sa ServiceAccount uses the principle of least privilege (do NOT grant it cluster-admin or overly broad permissions; it only needs to exec into pods in the finance-system namespace).

The PersistentVolume you create to satisfy the PVC must use hostPath at /opt/backups.