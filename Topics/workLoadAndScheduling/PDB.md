pod disruption budget tells k8s how many pods of an app must stay running during the voluntarily disruptions like node drain, upgrades or mainataince.It helps prevent too many replicas being evicted at the same time.

 what it does:-
 - it protects app availability during planned disruptions.
 - it can define either minAvailable or maxUnavailable.
 - it is respected by the eviction flow, so k8s checks the budget before allowing a pod to be removed.
 when it matters:-
 - during the manintainance or cluster upgrades.
 - for apps with multiple replicas that should not go down together, like databases ,queues, or critical APIs.
 - In production environment where uptime matters more than fast eviction.
 