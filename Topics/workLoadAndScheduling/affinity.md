# podAntiAffinity:
- it can be used when there is need for the HA cluster.
Now there are multiple cases
- required
- preferred
and also which topology to use
- zone
- hostname
- region
and also there is something modern called topologySpreadConstraints (most preferred)


#topologySpreadConstraints ensures Pods are evenly distributed across topology domains (zones, regions, nodes, etc.)
🧠 Conceptual Diagram
Without topologySpreadConstraints:
-----------------------------------
Scheduler → May place all Pods on one node
  tokyo-a-server: 7 Pods ❌ (all eggs in one basket)
  tokyo-b-server: 0 Pods

With topologySpreadConstraints (maxSkew: 1, minDomains: 2):
------------------------------------------------------------
Scheduler → Balances Pods across domains
  tokyo-a-server: 4 Pods ✅
  tokyo-b-server: 3 Pods ✅
  Difference: 1 (satisfies maxSkew: 1)
📊 Distribution Example (7 replicas, maxSkew: 1)
Valid distributions:
- Domain A: 4, Domain B: 3 ✅ (difference = 1)
- Domain A: 3, Domain B: 4 ✅ (difference = 1)

Invalid distributions:
- Domain A: 5, Domain B: 2 ❌ (difference = 3, exceeds maxSkew)
- Domain A: 7, Domain B: 0 ❌ (violates minDomains: 2)