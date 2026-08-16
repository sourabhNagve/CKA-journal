# Helm

Helm is the package manager for Kubernetes.

It bundles Kubernetes YAML into reusable packages called **Charts** and lets you install them as **Releases**.

It is useful when you manage the same application across environments like **dev, staging, and production**, with different settings.

## Key Concepts

### Chart

A reusable package containing Kubernetes manifests, templates, and configuration files such as:

```text
Chart.yaml
values.yaml
templates/
```

### Release

One installed instance of a Chart in a Kubernetes cluster.

```bash
helm install my-nginx bitnami/nginx
```

Here:

```text
my-nginx       → release name
bitnami/nginx  → chart reference
```

### Values

Values are configuration settings used to customize a Chart for different environments.

For example:

```yaml
replicaCount: 2
```

The same Chart can use different values for dev, staging, and production.

### Repository

A place where Helm Charts are stored and discovered.

Repositories can be public or private.

---

## How Helm Works

Helm takes:

```text
Templates + Values
        ↓
Rendered Kubernetes YAML
        ↓
Kubernetes API
        ↓
Resources in the cluster
```

This helps avoid maintaining many nearly identical Kubernetes YAML files for different environments.

---

## Basic Flow

```text
Install Helm CLI
      ↓
Add a Chart repository
      ↓
Search for a Chart
      ↓
Install the Chart
      ↓
Customize with Values
      ↓
Upgrade or Rollback
```

---

## Common Commands

```bash
# Add a Chart repository
helm repo add <repo-name> <repo-url>

# Refresh repository metadata
helm repo update

# Search for Charts
helm search repo <keyword>

# Install a Chart as a Release
helm install <release-name> <repo>/<chart>

# Upgrade an existing Release
helm upgrade <release-name> <repo>/<chart>

# Roll back to a previous revision
helm rollback <release-name> <revision>

# List installed Releases
helm list

# Show Release status
helm status <release-name>

# Show Release history
helm history <release-name>
```

---

## Set Custom Values

Using `--set`:

```bash
helm install my-nginx bitnami/nginx \
  --set service.type=LoadBalancer \
  --set replicaCount=2
```

Or using a values file:

```bash
helm install my-nginx bitnami/nginx -f values-prod.yaml
```

---

## Upgrade and Rollback

Upgrade:

```bash
helm upgrade my-nginx bitnami/nginx --set replicaCount=3
```

Check history:

```bash
helm history my-nginx
```

Roll back:

```bash
helm rollback my-nginx 1
```

---

## Remember the Chart Reference

```bash
helm install my-nginx repo-name/nginx-ingress
#           ↑              ↑
#      release name    chart reference
#                      repo/chart
```

So:

```text
my-nginx              → Release
repo-name/nginx       → Chart
```

### Simple Mental Model

```text
Chart + Values
      ↓
     Helm
      ↓
   Release
      ↓
 Kubernetes
```
