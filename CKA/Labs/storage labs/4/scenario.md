Scenario 4: The Ephemeral Exhaustion & Zonal Outage Trap
1. The Scenario
The cache-node deployment in the redis-cluster namespace is experiencing chaotic evictions because it writes heavily to local disk without constraints, causing node-level DiskPressure. When it crashes, it drops database connections violently, causing upstream errors. Furthermore, the pods are currently clumping onto a single availability zone, meaning a single zone failure will take down the entire cache tier.

Your Tasks:

Resource Bounding: Constrain the cache-node container to prevent it from consuming all node disk space. Set an ephemeral-storage limit of 1Gi and a request of 500Mi.

Graceful Termination: The application needs exactly 15 seconds to flush memory to disk before shutting down. Inject a preStop lifecycle hook that executes the command: /bin/sh -c "sleep 15".

Advanced Scheduling (Topology Spread): Replace any basic anti-affinity rules with a modern topologySpreadConstraint.

Ensure the pods are spread across zones (topologyKey: topology.kubernetes.io/zone).

The maxSkew must be 1.

The constraint should strictly prevent scheduling if the skew is violated (whenUnsatisfiable: DoNotSchedule).

Match the label app: cache-node.