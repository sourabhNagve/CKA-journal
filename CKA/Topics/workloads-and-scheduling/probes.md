# Kubernetes Probes

Kubernetes uses **probes** to check the health and availability of containers.

There are three main probes:

* **Readiness probe** → Can this Pod receive traffic?
* **Liveness probe** → Is this container still healthy/alive?
* **Startup probe** → Has this container finished starting?

---

## Readiness Probe

**Question:** Is this Pod ready to receive traffic?

If the readiness probe fails, Kubernetes removes the Pod from the **Service endpoints**, so the Service stops sending new requests to it.

The container is **not restarted**.

```text
Readiness fails
      ↓
Pod removed from Service endpoints
      ↓
No new traffic
      ↓
Container keeps running
```

Once the readiness probe succeeds again, the Pod can receive traffic again.

---

## Liveness Probe

**Question:** Is this container still alive and functioning?

If the liveness probe repeatedly fails, Kubernetes restarts the container.

```text
Liveness fails
      ↓
Container considered unhealthy
      ↓
Container restarted
```

It is useful for applications that are running but have become stuck or unable to recover by themselves.

---

## Startup Probe

**Question:** Has the application successfully started?

A startup probe is useful for **slow-starting applications**.

When a startup probe is configured, Kubernetes waits for it to succeed before running the liveness and readiness probes.

```text
Container starts
      ↓
Startup probe runs
      ↓
Startup succeeds
      ↓
Liveness + Readiness probes start
```

If the startup probe repeatedly fails, Kubernetes kills and restarts the container according to the Pod's restart policy.

### Problem it solves: Slow Starters

Some applications take a long time to start, for example:

* Large Java/Spring Boot applications
* Applications performing database migrations
* Legacy applications
* Applications with heavy initialization

Without a startup probe, a liveness probe might start failing while the application is still starting, causing Kubernetes to repeatedly restart it before it gets a chance to finish starting.

The startup probe acts as a **gatekeeper** until the application has successfully started.

---

# Probe Timing Settings

| Setting               | Default | Minimum | What it controls                                           |
| --------------------- | ------: | ------: | ---------------------------------------------------------- |
| `initialDelaySeconds` |     `0` |     `0` | Time to wait before the first probe                        |
| `periodSeconds`       |    `10` |     `1` | Time between probe attempts                                |
| `timeoutSeconds`      |     `1` |     `1` | Maximum time allowed for one probe                         |
| `failureThreshold`    |     `3` |     `1` | Consecutive failures before the probe is considered failed |
| `successThreshold`    |     `1` |     `1` | Consecutive successes required to become healthy           |

---

## Example

Suppose:

```yaml
initialDelaySeconds: 5
periodSeconds: 10
timeoutSeconds: 2
failureThreshold: 3
```

### Initial delay

The container starts.

Kubernetes waits **5 seconds** before the first probe.

```text
Container starts
     ↓
   5 sec
     ↓
First probe
```

### Probe interval

After that, Kubernetes performs the probe periodically according to:

```yaml
periodSeconds: 10
```

### Timeout

If:

```yaml
timeoutSeconds: 2
```

Kubernetes waits up to 2 seconds for that probe attempt.

If the application responds within 2 seconds → success.

If it takes longer → failure.

### Failure threshold

With:

```yaml
failureThreshold: 3
```

the probe must fail 3 consecutive times before Kubernetes takes the corresponding action.

For example:

```text
Probe 1 → FAIL
Probe 2 → FAIL
Probe 3 → FAIL
             ↓
       Threshold reached
```

For a **liveness/startup probe**, the container may be restarted.

For a **readiness probe**, the Pod is removed from Service endpoints but the container continues running.

> The exact time before action can vary slightly because probe scheduling starts after the previous probe attempt and other factors can affect timing. Don't assume it is always exactly `failureThreshold × periodSeconds`.

---

# Problems These Probes Solve

## 1. Startup Probe → "Slow Boot" Problem

### Problem

The application takes a long time to start.

If liveness checks begin too early, Kubernetes may think the application is broken and repeatedly restart it.

### Solution

Startup probe gives the application time to finish starting.

```text
Container starts
      ↓
Startup probe
      ↓
Application finishes booting
      ↓
Startup succeeds
      ↓
Liveness + Readiness begin
```

---

## 2. Liveness Probe → "Zombie App" Problem

### Problem

The container is still running, but the application is stuck or broken.

For example:

* Deadlock
* Infinite loop
* Application is no longer responding

### Solution

The liveness probe detects the unhealthy application and Kubernetes restarts the container.

```text
Application stuck
      ↓
Liveness fails
      ↓
Container restarted
      ↓
Application starts fresh
```

---

## 3. Readiness Probe → "Bad Traffic Routing" Problem

### Problem

A container can be running but temporarily unable to handle requests.

For example:

* Application is overloaded
* Dependency is temporarily unavailable
* Database connection is not ready

### Solution

The readiness probe prevents traffic from being sent to that Pod.

```text
Readiness fails
      ↓
Pod removed from Service endpoints
      ↓
Traffic goes to other ready Pods
      ↓
Pod recovers
      ↓
Readiness succeeds
      ↓
Pod receives traffic again
```

The container itself stays running.

---

# Important: Probe Configuration Must Match the Application

Probes can fail simply because the probe is configured incorrectly.

For example, if your application listens on:

```text
8080
```

but your probe checks:

```yaml
httpGet:
  path: /health
  port: 80
```

the probe will fail because Kubernetes is checking the wrong port.

Make sure these match the application:

```text
Application
    ↓
Listening on port 8080
    ↓
Probe checks port 8080
```

Also make sure the probe's:

* **Port** is correct
* **Path** is correct
* **Protocol** is correct
* **Named port**, if used, exists

Example:

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
```

If the application exposes its health endpoint on `/health` at port `8080`, this probe can check it correctly.

---

# Simple Mental Model

```text
Startup
   │
   │ "Has the app started?"
   ▼
Liveness
   │
   │ "Is the app still healthy?"
   ▼
Readiness
   │
   │ "Can the app receive traffic?"
   ▼
Service
```

Or remember:

```text
Startup   → Start me
Liveness  → Keep me alive
Readiness → Send me traffic
```
