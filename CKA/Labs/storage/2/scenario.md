1. The Scenario
The auth-service deployment in the identity namespace was rushed to production. It relies on a Secret for JWT signing keys that was deleted by accident, and its probes are misconfigured, causing load balancers to drop traffic intermittently. Furthermore, all pods are piling up on a single node, creating a massive single point of failure.

Your Tasks:

Immutable Configuration: Create a Secret named jwt-keys containing the key private.pem (with any dummy content). To prevent accidental modifications in production, this Secret must be set as immutable: true. Mount this secret into the container at /etc/certs as a read-only volume.

Aggressive Probes: Configure the liveness probe to check HTTP path /healthz on port 8080. It must be highly aggressive: timeoutSeconds: 1 and failureThreshold: 2.

High Availability (Anti-Affinity): Implement a strict (required) podAntiAffinity rule to ensure that no two auth-service pods are ever scheduled on the same node (use topologyKey: kubernetes.io/hostname).

Fix the Trap: The current Readiness probe is checking port 80, but the application actually runs on 8080. Fix this so endpoints populate correctly.