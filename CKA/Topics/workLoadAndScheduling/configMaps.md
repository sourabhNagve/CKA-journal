# ConfigMap

A **ConfigMap (CM)** is a Kubernetes API object used to store **non-confidential configuration data** as key-value pairs.

Pods can consume ConfigMaps as:

* Environment variables
* Command-line arguments
* Files mounted through a volume

ConfigMaps help **decouple environment-specific configuration from container images**, making applications easier to configure and move between environments.

---

## Example

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: production
  LOG_LEVEL: info
```

---

## Create ConfigMap from a File

If you want to create a ConfigMap from a file and give it an explicit name:

```bash
kubectl create configmap my-html-cm \
  --from-file=index.html=./index.html
```

Here:

```text
my-html-cm
    ↓
ConfigMap name

index.html=./index.html
    ↓
key      = source file
```

---

## ConfigMap Update Behavior

### Environment Variables

When a ConfigMap is consumed as environment variables:

```yaml
env:
  - name: APP_ENV
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: APP_ENV
```

Changes to the ConfigMap **do not update the environment variables inside an already-running container**.

You need to restart/recreate the Pod to pick up the new values.

The same applies when using `envFrom`.

```text
ConfigMap changes
      ↓
Existing Pod
      ↓
Environment variables stay unchanged
      ↓
Pod restart required
```

### Volume Mounts

When a ConfigMap is mounted as a volume, Kubernetes can update the files in the mounted volume when the ConfigMap changes.

However:

* The application must actually reload/watch the file to use the new configuration.
* Avoid `subPath` mounts if you need automatic ConfigMap updates.

```text
ConfigMap changes
      ↓
Mounted files can be updated
      ↓
Application must reload/read the new file
```

---

## Size Limit

A ConfigMap is limited to **1 MiB**.

Very large ConfigMaps can:

* Increase `etcd` load
* Slow down Pod startup
* Make configuration harder to manage

### Tip

Split large configurations into multiple ConfigMaps based on responsibility/concern.

For very large files, consider:

* Persistent Volumes
* Object storage
* External configuration services

---

## Common Issues

### 1. Key does not exist

The Pod references a ConfigMap key that isn't present.

```text
ConfigMap:
  APP_ENV

Pod expects:
  DB_HOST   ❌
```

### 2. Wrong `items` mapping

When mounting specific keys, make sure the key and file path are correct.

```yaml
items:
  - key: app.properties
    path: app.properties
```

### 3. Mount path conflicts

Be careful when mounting a ConfigMap over a directory that already contains important files.

The mounted volume can hide the existing files at that mount location.

---

## Remember

```text
ConfigMap
    ↓
Non-confidential configuration
    ↓
 ┌───────────────┬─────────────────┐
 ↓               ↓                 ↓
env            envFrom          volume
 ↓               ↓                 ↓
No auto       No auto          Files can
update        update           be updated
 ↓               ↓                 ↓
Pod restart    Pod restart      App must
required       required         reload/read
```

> **ConfigMap = configuration, not secrets.** Use a Kubernetes `Secret` or an external secret-management solution for sensitive data such as passwords, tokens, and API keys.
