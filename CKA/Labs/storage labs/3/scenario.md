Scenario 3: The Starving HPA & Environment Collision
1. The Scenario
The data-processor deployment in the data-pipeline namespace is meant to autoscale based on heavy loads. However, the current HPA is fundamentally broken because it cannot calculate metrics. Furthermore, legacy environment variables hardcoded in the deployment manifest are colliding with the new centralized configuration standard.

Your Tasks:

Enable Autoscaling Metrics: Modify the deployment to include strict resource requests (CPU: 100m, Memory: 128Mi) so the metrics-server can establish a baseline.

Deploy v2 HPA: Create a modern HorizontalPodAutoscaler (API autoscaling/v2) named data-processor-hpa.

Target the data-processor deployment.

Scale between minReplicas: 2 and maxReplicas: 5.

Scale up if average CPU utilization hits 60% OR if average Memory utilization hits 75%.

Environment Refactor:

Create a ConfigMap named app-settings containing LOG_LEVEL=DEBUG and BATCH_SIZE=500.

The deployment currently has these variables hardcoded directly in the env array. Remove the hardcoded values.

Inject the ConfigMap into the container using envFrom to load all keys automatically.