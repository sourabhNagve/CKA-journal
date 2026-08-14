A critical financial processing deployment (finance-api) is in a severely degraded state after a botched automated rollout. The current revision is crash-looping because of aggressive, misconfigured probes and a missing secret. Furthermore, the cluster administrators recently cordoned off the default node pool and created a dedicated secure tier, but the deployment's scheduling constraints are pointing to non-existent labels and lacking proper tolerations.

Your Tasks:

Rollback & Stabilize: Roll back the finance-api deployment in the finance-system namespace to the previous working revision (Revision 1).

Zero-Downtime Reconfiguration: Update the deployment strategy to ensure absolute zero downtime during future updates (maxUnavailable: 0 and maxSurge: 25%).

Scheduling Mastery:

Modify the deployment so it only schedules on nodes with the label tier=secure (using required nodeAffinity).

The secure nodes have a taint: security-level=high:NoSchedule. Add the exact toleration to allow the pods to schedule there.

Resource Constraints: Enforce strict resource boundaries to prevent noisy neighbor issues. Set requests to CPU: 200m, Memory: 256Mi and limits to CPU: 500m, Memory: 512Mi.