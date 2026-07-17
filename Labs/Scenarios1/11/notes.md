maxSurge means how many extra Pods Kubernetes can create above the desired replica count during a rolling update.

maxUnavailable means how many of the desired Pods are allowed to be down at the same time during the update.

Easy way to think about it
Surge = extra temporary capacity.

Unavailable = how much capacity you are willing to lose briefly.