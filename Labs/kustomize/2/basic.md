# exam-question.md

## 1. Exam Scenario

Task:
A junior engineer has been working on a Kustomize project located at `/root/cka-lab/kustomize-app` to deploy a frontend application. The project consists of a `base` configuration and a `staging` overlay. 

The engineer attempted to deploy the staging overlay, but the deployment failed due to multiple configuration errors in the `staging` directory.

Your task is to fix the Kustomize configuration in the `staging` directory and successfully deploy the application to the cluster.

Ensure the following requirements are met for the staging deployment:
1. All resources must be deployed into the `ecommerce-staging` namespace.
2. All resource names must have the prefix `staging-`.
3. The frontend deployment must have exactly `3` replicas.
4. The frontend deployment's container must use the `nginx:1.25.3-alpine` image.
5. The frontend deployment's container must include an environment variable named `APP_ENV` with the value `staging`.
6. Apply the fixed `staging` overlay to the cluster.

## 2. Initial Cluster State

- Namespace: `ecommerce-staging` (created, empty)
- Directory: `/root/cka-lab/kustomize-app` containing:
  - `base/` (Contains valid `deployment.yaml`, `service.yaml`, and `kustomization.yaml`)
  - `staging/` (Contains broken `kustomization.yaml` and broken `patch.yaml`)
- The cluster currently has no resources deployed from this project.

## 6. Expected kubectl Outputs

When examining the broken state (attempting a dry-run):