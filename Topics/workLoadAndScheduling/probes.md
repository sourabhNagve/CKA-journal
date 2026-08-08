Readiness probe:
is this pod ready to recieve traffic,if it failts k8s removes the pod from the service endpoints , so new request stop going to it.

Liveness probe:
is this container still alive, if it fails k8s restarts the container.

startup probe: its a health check used to determine if a container has successfully started.
if the startup probe has configured then it will act as a gatekeeper for hte pod.  it disables both liveness and the readiness probes till it succeed.
if the startup probe never succeed so k8s will kill the container and restarts it according to the pods restartpolicy.

The porblem it solves : Slow Starters
Before startup probes were introduced, handling legacy or heavy applications that took a long time to boot up (like a massive Java Spring Boot app or a database that needs to run migrations) was difficult.

## The Five Timing Settings

| Setting | Default | Minimum | What it controls |
| :--- | :---: | :---: | :--- |
| **`initialDelaySeconds`** | `0` | `0` | How long to wait after the container starts before running the *very first* check. |
| **`periodSeconds`** | `10` | `1` | How often to perform the check. |
| **`timeoutSeconds`** | `1` | `1` | How long to wait for a single check attempt to return a response. |
| **`failureThreshold`** | `3` | `1` | How many consecutive times the check must fail before Kubernetes takes action. |
| **`successThreshold`** | `1` | `1` | How many consecutive times the check must succeed to be marked healthy. |



Here is exactly what happens over time:

The Initial Wait (initialDelaySeconds: 5)
The container starts. Kubernetes sets a stopwatch and does absolutely nothing for 5 seconds. It gives the container a moment to breathe.

The First Check (periodSeconds: 10)
At the 5-second mark, Kubernetes sends the first probe (e.g., an HTTP GET request). It will now wait 10 seconds before sending the next one.

The Response Window (timeoutSeconds: 2)
When Kubernetes sends that HTTP request, it waits exactly 2 seconds for the application to respond with a 200 OK.

If the app responds in 1.5 seconds, it's a success.

If the app takes 2.5 seconds to respond, Kubernetes cuts the connection at 2 seconds and counts it as a failure.

The Three-Strike Rule (failureThreshold: 3)
Kubernetes doesn't kill the pod after one failure. It keeps a tally. If the probe times out or returns an error three times in a row, the threshold is breached.

For a Startup or Liveness probe: The container is instantly killed and restarted.

For a Readiness probe: The pod is removed from the network traffic (LoadBalancer/Service) so users don't get routed to a broken app, but the container keeps running while Kubernetes keeps checking it.
Key insight: The total time your application has to completely fail before Kubernetes steps in is failureThreshold × periodSeconds. In the example above, the app has to be unresponsive for 30 seconds (3 failures × 10 seconds) before Kubernetes takes action.


PROBLEMS THESE PROBES SOLVES
1. Startup Probe: Solves the "Slow Boot" Problem
The Problem: Some applications take a long time to start. A legacy Java application might take 2 minutes to initialize, or an app might need to run database migrations before it can serve traffic. If Kubernetes starts checking if the app is "alive" during this boot process, the app won't respond. Kubernetes will assume it's broken, kill it, and restart it—creating an infinite loop where the app is never allowed to finish booting.

The Solution: The startup probe acts as a shield. It tells Kubernetes: "Do not apply any normal health checks until this specific boot sequence is completely finished."

Action taken: Pauses all other probes. Once it succeeds, it permanently gets out of the way.

2. Liveness Probe: Solves the "Zombie App" Problem
The Problem: Sometimes an application is still technically running (the container hasn't crashed), but it is completely broken and unable to recover. It might be caught in an infinite loop, suffering from a deadlock, or out of memory. If Kubernetes doesn't intervene, this "zombie" pod will just sit there consuming resources while doing no work.

The Solution: The liveness probe is the system's "reboot switch." It periodically checks if the core application loop is functioning. If the app becomes permanently stuck and stops responding to the liveness check, Kubernetes knows the only way to fix it is to turn it off and back on again.

3. Readiness Probe: Solves the "Bad Traffic Routing" Problem
The Problem: Just because an application is running (alive) doesn't mean it is ready to receive user traffic. It might be temporarily overwhelmed with requests, or it might have briefly lost its connection to the database. If Kubernetes routes a user's request to this pod, the user will get an error.

The Solution: The readiness probe controls the network valve. It constantly checks: "Can this pod handle a user request right now?" If the app is temporarily overwhelmed or waiting for a database to return, the readiness probe fails. Kubernetes stops sending user traffic to that specific pod, redirecting it to other healthy pods instead.

Action taken: Removes the pod from the LoadBalancer/Service. The container stays alive, giving it time to recover. Once it recovers, traffic is turned back on.


---------------------
probes fails if the image is built on some port and you use wrong ports in the yaml