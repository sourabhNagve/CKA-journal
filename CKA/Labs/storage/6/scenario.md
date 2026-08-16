Scenario 6: The Zombie InitContainer & Throttled Scale-Down
1. The Scenario
The order-processor deployment in the transactions namespace is stuck in Init:CrashLoopBackOff. Its initContainer is designed to run a database migration script, but the script is missing because the required ConfigMap was never created.
Furthermore, the HPA controlling this deployment (order-hpa) scales down too aggressively during traffic dips, which causes massive cache misses.

Your Tasks:

Fix the Init Sequence: Create a ConfigMap named db-init-script containing a file called migrate.sh (with the content echo "Migrating...").

Mount the Script: Modify the deployment's initContainer. Mount the db-init-script ConfigMap to /scripts and ensure the initContainer executes sh /scripts/migrate.sh.

Advanced HPA Behavior (Throttled Scale-Down): Update the order-hpa HorizontalPodAutoscaler to restrict how fast it can scale down.

Add a behavior block.

Configure the scaleDown policy to allow scaling down by a maximum of 1 pod per minute (60 seconds).

Keep the scaleUp policies at their defaults.