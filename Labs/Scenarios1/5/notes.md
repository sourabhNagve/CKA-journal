readiness probe
Used for traffic routing.
If it fails, the pod stays running but is removed from Service endpoints, so it stops receiving requests.
Good for startup warm-up, database connections, cache loading, or any time the app is alive but not ready.

liveness probe

Used for self-healing.

If it fails, Kubernetes restarts the container.

Readiness = “Can I send traffic now?”

Liveness = “Should I restart this container?


----------------------------------------
reasons of not having the endpoints even if the labels matches.
Pods fail readiness probes, so they exist but are not added to Service endpoints.
 the most common reasons a Service has no endpoints are: the pods are not Ready,
A failing readiness probe usually means the pod is running but not ready to receive traffic.

The fastest fix is to inspect the probe target, then compare it with what the app actually serves inside the container.
A 404 from a probe usually means the endpoint exists on the container, but the specific path you configured does not. In Kubernetes, HTTP probes treat 200–399 as success, so a 404 makes the pod unready and removes it from Service endpoints.
This readiness probe will fail on plain nginx:alpine because the probe is checking GET /healthz on port 80, and default NGINX usually serves / but not /healthz, so Kubernetes will likely get HTTP 404 and mark the pod unready.

The container is listening on port 80, so the port is probably fine, but the path /healthz is the likely problem. A readiness probe succeeds only when the endpoint returns a success status, and 404 means “path not found,” not “app ready.”

Fix options
Change the probe path to / if default NGINX is enough for the task.

Or keep /healthz and configure NGINX to actually serve that endpoint.

If startup is slow, also tune initialDelaySeconds, but that does not fix a 404 path mismatch.