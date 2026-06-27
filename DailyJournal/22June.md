requiredDuringSchedulingIgnoredDuringExecution (hard requirement)
- pod must be placed on nodes matching the rules otherwise they will be in pending state.
- similar to nodeselector but it is more expressive.
preferredDuringSchedulingIgnoredDuringExecution (preference)
- scheduler prefers node matching the rules, if not matching node exits, pod can still be scheduled.
** weight: 50 in preferred NodeAffinity only influences scoring and cannot ensure equal pod distribution, use topologySpreadConstraints with maxSkew: 1 for guaranteed even spreading.

--------------------------

OOM kills: memory limits too low
CPU Throttling: limits too restrictive
failed scheduling: requests exceeds node capacity.
Node pressure: too many pods consuming resources.

----------------------------

Storage class defines different types of storage cluster offers,to automatically create volumes when needed
without this you have to manually create pv and provision the volume
storage class template tells:
- kind of storage it creates(ssd,hdd, cloud disk etc)
- how fast it should be (performance tiers)
- who creates it (the provisioner)
- what happens when deleted(reclaim policy) 