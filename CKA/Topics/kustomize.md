# Kustomize: Bases, Overlays, Components, Generators, Patches, and Transformers

Kustomize is a Kubernetes-native configuration management tool. It lets you define a common set of Kubernetes manifests and then customize them for different environments without copying the base YAML.

A typical Kustomize setup looks like this:

```text
base
  ↓
overlay
  ↓
final Kubernetes manifests
```

The main concepts are:

* **`kustomization.yaml`** — the entry point for a Kustomize directory
* **Base** — reusable, environment-independent Kubernetes resources
* **Overlay** — environment-specific customization of one or more bases
* **Component** — reusable optional functionality
* **Generator** — creates ConfigMaps and Secrets
* **Patch** — modifies existing resources
* **Transformer** — modifies resource metadata or fields globally

---

## 1. `kustomization.yaml`

`kustomization.yaml` is the main configuration file for a Kustomize directory.

It tells Kustomize:

* Which Kubernetes resources to include
* Which bases or other Kustomizations to use
* Which components to include
* Which patches to apply
* Which ConfigMaps and Secrets to generate
* Which transformations to perform

For example:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
```

When you run:

```bash
kubectl apply -k overlays/prod
```

`kubectl` reads the `kustomization.yaml` inside `overlays/prod` and builds the final manifests.

You can also preview the generated manifests:

```bash
kubectl kustomize overlays/prod
```

or:

```bash
kustomize build overlays/prod
```

---

# 2. Bases

A **base** is a directory containing its own `kustomization.yaml` and a reusable set of Kubernetes resources.

A base normally contains the application's common/default configuration.

For example:

```text
base/
├── kustomization.yaml
├── deployment.yaml
└── service.yaml
```

A good base should generally be:

* Reusable
* Environment-independent
* Free from production/dev-specific assumptions
* Usable by multiple overlays

For example, the base might define:

```yaml
replicas: 1
```

while a production overlay changes it to:

```yaml
replicas: 5
```

The base should not need to know whether it is being deployed to `dev`, `staging`, or `prod`.

---

# 3. Overlays

An **overlay** customizes a base for a particular environment.

For example:

```text
overlays/
├── dev/
├── staging/
└── prod/
```

An overlay can:

* Reference one or more bases
* Set a namespace
* Add labels
* Add a name prefix
* Change image tags
* Change replicas
* Generate environment-specific ConfigMaps/Secrets
* Apply patches
* Include optional components

Conceptually:

```text
                    ┌── dev overlay
                    │
base ───────────────┼── staging overlay
                    │
                    └── prod overlay
```

This allows all environments to share the same application definition while still having their own configuration.

---

# 4. Components

A **component** is a reusable set of Kustomize configuration intended to provide an optional feature.

For example:

```text
components/
└── monitoring/
    ├── kustomization.yaml
    └── prometheus-servicemonitor.yaml
```

A monitoring component could add:

* A `ServiceMonitor`
* Monitoring-related labels
* Additional configuration required for monitoring

Multiple overlays can reuse the same component:

```text
dev     ──┐
staging ──┼──> monitoring component
prod    ──┘
```

This is useful when a feature should be **enabled selectively** without duplicating the configuration in every overlay.

> **Note:** Kustomize Components use the `Component` kind and have historically been marked as alpha functionality. Check the Kustomize version bundled with your `kubectl` if you are using components in production.

---

# 5. Example Directory Structure

A complete example application can look like this:

```text
my-app/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
│
├── components/
│   └── monitoring/
│       ├── kustomization.yaml
│       └── prometheus-servicemonitor.yaml
│
└── overlays/
    └── prod/
        ├── kustomization.yaml
        ├── deployment-replicas-patch.yaml
        ├── prod-config.properties
        └── prod-secret.txt
```

The responsibility of each directory is:

| Directory        | Purpose                           |
| ---------------- | --------------------------------- |
| `base/`          | Common application configuration  |
| `components/`    | Optional reusable features        |
| `overlays/prod/` | Production-specific configuration |

---

# 6. Base: Application Configuration

## `base/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1

  selector:
    matchLabels:
      app: my-app

  template:
    metadata:
      labels:
        app: my-app

    spec:
      containers:
        - name: my-app
          image: myorg/my-app:latest

          ports:
            - name: http
              containerPort: 8080

          env:
            - name: APP_ENV
              value: "unknown"

            - name: DB_HOST
              valueFrom:
                configMapKeyRef:
                  name: my-app-config
                  key: DB_HOST

          volumeMounts:
            - name: config-volume
              mountPath: /app/config
              readOnly: true

      volumes:
        - name: config-volume
          configMap:
            name: my-app-config
```

Notice that the container port is named `http`. This is useful because the ServiceMonitor component can reference the Service's `http` port consistently.

---

## `base/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app

spec:
  selector:
    app: my-app

  ports:
    - name: http
      port: 80
      targetPort: 8080

  type: ClusterIP
```

---

## `base/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

configMapGenerator:
  - name: my-app-config
    literals:
      - DB_HOST=base-db.local
```

### What is happening here?

`resources` tells Kustomize which Kubernetes manifests belong to the base:

```yaml
resources:
  - deployment.yaml
  - service.yaml
```

`configMapGenerator` creates a ConfigMap:

```yaml
configMapGenerator:
  - name: my-app-config
    literals:
      - DB_HOST=base-db.local
```

The resulting ConfigMap will contain:

```yaml
DB_HOST: base-db.local
```

The base therefore provides a sensible default configuration while remaining environment-independent.

---

# 7. `configMapGenerator`

`configMapGenerator` can generate a ConfigMap from:

* Literals
* Environment files
* Files

For example, to generate a ConfigMap from a file:

```yaml
configMapGenerator:
  - name: my-app-config
    files:
      - app.properties
```

If `app.properties` contains:

```text
DB_HOST=prod-db.internal
LOG_LEVEL=warn
```

Kustomize creates a ConfigMap containing the file as a data entry.

You can also control the key name:

```yaml
configMapGenerator:
  - name: my-app-config
    files:
      - application.properties=prod-config.properties
```

Here:

* `prod-config.properties` is the source file
* `application.properties` becomes the ConfigMap key

---

# 8. Components: Monitoring

## `components/monitoring/prometheus-servicemonitor.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor

metadata:
  name: my-app-monitor

spec:
  selector:
    matchLabels:
      app: my-app

  endpoints:
    - port: http
      path: /metrics
      interval: 30s
```

The `port: http` refers to the named port on the Service:

```yaml
ports:
  - name: http
    port: 80
    targetPort: 8080
```

---

## `components/monitoring/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - prometheus-servicemonitor.yaml

commonLabels:
  monitoring: enabled
```

This component adds the monitoring configuration and applies the `monitoring=enabled` label through its Kustomize configuration.

The same component can then be reused by multiple overlays.

---

# 9. Production Overlay

The production overlay combines:

1. The base
2. The monitoring component
3. Production-specific configuration

## `overlays/prod/deployment-replicas-patch.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: my-app

spec:
  replicas: 5
```

This patch changes:

```yaml
replicas: 1
```

from the base to:

```yaml
replicas: 5
```

---

## `overlays/prod/prod-config.properties`

```properties
DB_HOST=prod-db.internal
LOG_LEVEL=warn
```

---

## `overlays/prod/prod-secret.txt`

```text
supersecret123
```

For a real GitHub repository, **do not commit real passwords or other credentials to this file**. Use a secret-management solution or an encrypted-secret workflow instead.

---

# 10. Production `kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Use the common application configuration
resources:
  - ../../base

# Enable monitoring for production
components:
  - ../../components/monitoring

# Deploy resources into the prod namespace
namespace: prod

# Prefix resource names with "prod-"
namePrefix: prod-

# Add environment/team metadata
commonLabels:
  environment: prod
  team: platform

# Change the application image
images:
  - name: myorg/my-app
    newTag: v1.2.3-prod

# Extend the ConfigMap generated by the base
configMapGenerator:
  - name: my-app-config
    behavior: merge

    files:
      - app.properties=prod-config.properties

    literals:
      - APP_ENV=prod

# Generate a production Secret
secretGenerator:
  - name: my-app-secret
    files:
      - DB_PASSWORD=prod-secret.txt

# Increase production replicas
patches:
  - path: deployment-replicas-patch.yaml

# Configure generated resources
generatorOptions:
  labels:
    app: my-app
```

---

# 11. Understanding the Production Overlay

### `resources`

```yaml
resources:
  - ../../base
```

Imports the base configuration.

The production overlay does not need to copy the Deployment or Service.

---

### `components`

```yaml
components:
  - ../../components/monitoring
```

Enables the reusable monitoring feature.

---

### `namespace`

```yaml
namespace: prod
```

Kustomize applies the namespace transformation to namespaced resources.

The resulting Deployment, Service, ConfigMap, etc. will be targeted at:

```yaml
namespace: prod
```

---

### `namePrefix`

```yaml
namePrefix: prod-
```

Adds `prod-` to resource names.

For example:

```text
my-app
```

becomes:

```text
prod-my-app
```

Kustomize also updates references to renamed generated resources where appropriate.

---

### `commonLabels`

```yaml
commonLabels:
  environment: prod
  team: platform
```

Adds common metadata labels to resources managed by the Kustomization.

Kustomize also handles relevant selector updates where the transformation applies, which is why label changes should be made deliberately: changing selectors can affect how Kubernetes associates Pods and controllers.

---

### `images`

```yaml
images:
  - name: myorg/my-app
    newTag: v1.2.3-prod
```

The base contains:

```yaml
image: myorg/my-app:latest
```

The overlay changes it to:

```yaml
image: myorg/my-app:v1.2.3-prod
```

This allows the base to remain unchanged while each environment chooses its own image version.

---

# 12. ConfigMap Generator Merge

The base creates:

```yaml
configMapGenerator:
  - name: my-app-config
    literals:
      - DB_HOST=base-db.local
```

The production overlay uses:

```yaml
configMapGenerator:
  - name: my-app-config
    behavior: merge
```

and adds:

```yaml
files:
  - app.properties=prod-config.properties

literals:
  - APP_ENV=prod
```

The important part is:

```yaml
behavior: merge
```

This tells Kustomize that the production generator should merge with the existing generated ConfigMap rather than creating an unrelated replacement.

The production configuration therefore extends/overrides the base configuration.

---

# 13. Secret Generator

The overlay contains:

```yaml
secretGenerator:
  - name: my-app-secret
    files:
      - DB_PASSWORD=prod-secret.txt
```

Kustomize generates a Secret from the file.

By default, generated ConfigMaps and Secrets receive a content hash suffix.

For example:

```text
prod-my-app-config-7gk9f4k2
prod-my-app-secret-8m5d7h6f
```

The hash is useful because changing the generated data changes the resource name, which can help trigger updates when referenced by workloads.

Kustomize also tracks references to generated resources and updates them accordingly.

> **Security:** Never put a real production password such as `supersecret123` in a public GitHub repository. For a public example, use a fake value and clearly mark it as an example.

---

# 14. Patches

The overlay contains:

```yaml
patches:
  - path: deployment-replicas-patch.yaml
```

The patch contains:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 5
```

Kustomize matches the Deployment and changes its replica count.

Base:

```yaml
replicas: 1
```

Production:

```yaml
replicas: 5
```

The modern `patches` field can support different patch types, including Strategic Merge Patch and JSON 6902 Patch. Kustomize determines the patch type based on the patch content when using the file form shown above.

---

# 15. Generators vs Transformers vs Patches

These concepts are easy to confuse.

### Generators

Generators **create new resources**.

Examples:

```yaml
configMapGenerator:
secretGenerator:
```

Think:

> "Create a ConfigMap or Secret for me."

---

### Transformers

Transformers **modify resources**.

Examples in this configuration include:

```yaml
namespace:
namePrefix:
commonLabels:
images:
```

Think:

> "Take the resources I've already defined and change them consistently."

---

### Patches

Patches **make targeted changes to specific resources**.

Example:

```yaml
patches:
  - path: deployment-replicas-patch.yaml
```

Think:

> "Change this specific Deployment."

---

# 16. Build the Production Manifests

From the repository root:

```bash
kubectl kustomize overlays/prod
```

This prints the final Kubernetes YAML without applying it.

You can also use standalone Kustomize:

```bash
kustomize build overlays/prod
```

This is useful for reviewing exactly what will be generated.

---

# 17. Apply to Kubernetes

To build and apply the overlay directly:

```bash
kubectl apply -k overlays/prod
```

The `-k` tells `kubectl` to use Kustomize.

Conceptually:

```text
kubectl apply -k overlays/prod
                  │
                  ▼
        overlays/prod/kustomization.yaml
                  │
          ┌───────┴────────┐
          ▼                ▼
        base          monitoring
          │            component
          └───────┬────────┘
                  ▼
        production patches
        + generators
        + transformations
                  │
                  ▼
          final Kubernetes YAML
                  │
                  ▼
             Kubernetes
```

---

# 18. What the Final Configuration Looks Like

The exact generated names and hashes depend on the Kustomize version and generated content, but conceptually the final resources will look like:

### Deployment

```text
name: prod-my-app
namespace: prod
replicas: 5
image: myorg/my-app:v1.2.3-prod
```

with labels such as:

```text
environment: prod
team: platform
monitoring: enabled
```

### Service

```text
name: prod-my-app
namespace: prod
port: 80
targetPort: 8080
```

### ConfigMap

Conceptually:

```text
name: prod-my-app-config-<hash>

DB_HOST: prod-db.internal
LOG_LEVEL: warn
APP_ENV: prod
app.properties: |
  DB_HOST=prod-db.internal
  LOG_LEVEL=warn
```

### Secret

```text
name: prod-my-app-secret-<hash>
```

containing the generated secret data.

### ServiceMonitor

```text
name: prod-my-app-monitor
namespace: prod
```

with the monitoring configuration supplied by the component.

---

# 19. How Everything Fits Together

The entire example can be summarized like this:

```text
                         Kustomize
                             │
                ┌────────────┴────────────┐
                │                         │
              Base                    Components
                │                         │
       ┌────────┴────────┐          Monitoring
       │                 │
  Deployment          Service
       │
       └──────────────┐
                      │
                      ▼
                Prod Overlay
                      │
        ┌─────────────┼─────────────┐
        │             │             │
      Patch       Generators     Transformers
        │             │             │
    replicas=5   ConfigMap       namespace
                 Secret          namePrefix
                                 labels
                                 image
                      │
                      ▼
             Final Kubernetes Manifests
                      │
                      ▼
               kubectl apply -k
```

---

# 20. Quick Reference

| Kustomize Concept    | Purpose                            | Example                  |
| -------------------- | ---------------------------------- | ------------------------ |
| `kustomization.yaml` | Main Kustomize configuration       | `resources`, `patches`   |
| Base                 | Common reusable configuration      | `base/`                  |
| Overlay              | Environment-specific customization | `overlays/prod/`         |
| Component            | Reusable optional feature          | `components/monitoring/` |
| `resources`          | Include Kubernetes manifests       | `deployment.yaml`        |
| `configMapGenerator` | Generate ConfigMaps                | `files`, `literals`      |
| `secretGenerator`    | Generate Secrets                   | `files`, `literals`      |
| `patches`            | Modify specific resources          | `replicas: 5`            |
| `namespace`          | Set namespace                      | `prod`                   |
| `namePrefix`         | Prefix resource names              | `prod-`                  |
| `commonLabels`       | Add common labels                  | `environment: prod`      |
| `images`             | Change image/tag                   | `newTag: v1.2.3-prod`    |
| `generatorOptions`   | Configure generated resources      | labels, hash behavior    |

---

# 21. Key Takeaway

The main idea behind Kustomize is:

> **Keep the common configuration in a base and apply environment-specific customization through overlays.**

Instead of maintaining separate copies of:

```text
deployment-dev.yaml
deployment-staging.yaml
deployment-prod.yaml
```

you maintain one base:

```text
base/deployment.yaml
```

and customize it:

```text
overlays/dev/
overlays/staging/
overlays/prod/
```

This gives you:

* Less YAML duplication
* Clear separation between common and environment-specific configuration
* Reusable components
* Declarative configuration
* Easier Git-based reviews
* Environment-specific image/configuration changes
* A clean GitOps-friendly repository structure

The most important mental model is:

```text
BASE
  │
  │ common configuration
  ▼
OVERLAY
  │
  │ environment-specific changes
  ▼
FINAL MANIFEST
  │
  │
  ▼
KUBERNETES
```
