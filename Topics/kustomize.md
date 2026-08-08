configMapGenerator: To generate cm from a file, add an entry to the files list in configmapGenerator.

kustomization.yaml (main entry file for any kustomize directory\)
- which resources to include
- which bases,overlays,components to use
- what patches, generators and transformers to apply
this is the fike what k apply -k reads

Bases:
a base is a directory with its own kustomization.yaml, it defies a reusable set of kubernets resources(deployment, svcs, cm etc)
- contains the common or default config
- has no knowledge of the environment (dev,prod,etc)
- can be used by multiple overlays.

Overlays:
An overlay is another kustomization.yaml that:

references one or more bases

adds environment‑specific changes (namespace, replicas, patches, labels, etc.)
Overlays produce the final manifests for a particular environment like dev, staging, or prod

Components:
A special kind of kustomization meant for reusable feature blocks (e.g., “enable monitoring”, “add Redis”, “external DB”).

Can be included in multiple overlays

Let you mix-and-match features without duplicating logic

-------------------------------
example
Directory layout
text
my-app/
├─ base/
│  ├─ kustomization.yaml
│  ├─ deployment.yaml
│  └─ service.yaml
├─ components/
│  └─ monitoring/
│     ├─ kustomization.yaml
│     └─ prometheus-servicemonitor.yaml
└─ overlays/
   └─ prod/
      ├─ kustomization.yaml
      ├─ deployment-replicas-patch.yaml
      ├─ prod-config.properties
      └─ prod-secret.txt
1. Base: shared app configuration
base/deployment.yaml
text
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
            - containerPort: 8080
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
base/service.yaml
text
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
base/kustomization.yaml
text
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

# Optionally generate a base ConfigMap if you want
configMapGenerator:
  - name: my-app-config
    literals:
      - DB_HOST=base-db.local
What this does:

resources lists the raw Kubernetes YAML files.

configMapGenerator creates a ConfigMap named my-app-config with a default DB_HOST.

This base is environment‑agnostic and reusable.

2. Component: reusable feature (monitoring)
components/monitoring/prometheus-servicemonitor.yaml
text
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
components/monitoring/kustomization.yaml
text
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - prometheus-servicemonitor.yaml

commonLabels:
  monitoring: enabled
What this does:

Component is a special kustomization meant to be included in multiple overlays.

It adds a ServiceMonitor and a label monitoring=enabled to everything it touches.

You can reuse this component in prod, staging, etc., without copying files.

3. Overlay: production environment
This overlay:

Uses the base

Includes the monitoring component

Sets namespace, name prefix, common labels

Overrides image tag

Patches replicas

Generates environment‑specific ConfigMap and Secret

Uses a strategic merge patch file

overlays/prod/deployment-replicas-patch.yaml
text
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 5
overlays/prod/prod-config.properties
text
DB_HOST=prod-db.internal
LOG_LEVEL=warn
overlays/prod/prod-secret.txt
text
DB_PASSWORD=supersecret123
overlays/prod/kustomization.yaml
text
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Base to customize
resources:
  - ../../base

# Include reusable component
components:
  - ../../components/monitoring

# Namespace for all resources
namespace: prod

# Naming helpers
namePrefix: prod-
commonLabels:
  environment: prod
  team: platform

# Override image tag across all Deployments
images:
  - name: myorg/my-app
    newTag: v1.2.3-prod

# Generate ConfigMap from file + literals
configMapGenerator:
  - name: my-app-config
    behavior: merge
    files:
      - app.properties=prod-config.properties
    literals:
      - APP_ENV=prod

# Generate Secret from file
secretGenerator:
  - name: my-app-secret
    files:
      - DB_PASSWORD=prod-secret.txt

# Patch the Deployment to increase replicas
patches:
  - path: deployment-replicas-patch.yaml

# Optional: customize how generators behave
generatorOptions:
  disableNameSuffixHash: false
  labels:
    app: my-app
Explanation of key fields:

resources: - ../../base
Pulls in the base app manifests.

components: - ../../components/monitoring
Adds monitoring resources and labels.

namespace: prod
All resources get metadata.namespace: prod.

namePrefix: prod-
All resource names become prod-my-app, prod-my-app-config, etc.

commonLabels
Adds environment=prod and team=platform to all resources and relevant selectors.

images
Rewrites myorg/my-app:latest → myorg/my-app:v1.2.3-prod in all Deployments.

configMapGenerator with behavior: merge
Merges with the base my-app-config instead of replacing it, adding/overriding keys from prod-config.properties and the literal APP_ENV=prod.

secretGenerator
Creates a Secret my-app-secret containing DB_PASSWORD.

patches
Applies the strategic merge patch to set replicas: 5 on the Deployment.

generatorOptions
Controls naming and labels on generated ConfigMaps/Secrets.

4. How to use it
From the repo root:

bash
# See the final YAML for prod
kubectl kustomize overlays/prod

# Or with standalone kustomize
kustomize build overlays/prod

# Apply directly to cluster
kubectl apply -k overlays/prod
Conceptually, the final output will include (names shortened):

Deployment

name: prod-my-app

namespace: prod

labels: app=my-app, environment=prod, team=platform, monitoring=enabled

image: myorg/my-app:v1.2.3-prod

replicas: 5

env from prod-my-app-config

Service

name: prod-my-app

namespace: prod

labels as above

ConfigMap

name: prod-my-app-config-<hash>

keys: DB_HOST, LOG_LEVEL, APP_ENV, plus app.properties content

Secret

name: prod-my-app-secret-<hash>

key: DB_PASSWORD

ServiceMonitor (from component)

name: prod-my-app-monitor

namespace: prod

labels include monitoring=enabled, environment=prod, etc.

How this maps to the main Kustomize terms
Base: base/ with deployment, service, base ConfigMap.

Overlay: overlays/prod/ customizing the base for production.

Component: components/monitoring/ reusable feature.

Generators: configMapGenerator, secretGenerator.

Transformers: namespace, namePrefix, commonLabels, images.

Patches: patches with deployment-replicas-patch.yaml.

kustomization.yaml: the central file in each directory declaring all of this.

If you want, I can next show a minimal dev overlay that uses the same base and component but with different replicas, image tag, and config.