Helm is the package manager for k8s.
it bundles k8s yaml into reusable packages called charts, lets you install them as releases.
it is useful when you manage same app across dev, staging and productin with different settings.

Chart: a reusable package that contains kubernetes manifests, templates and config files like Chart.yaml, values.yaml.
Release: one running installation of a chart in a cluster.
Values: here you can change settings for different envs, and use the same chart with different settings.
repo: a place to discover and fetch charts, such as public or private chart registeries.

How Helm works:
Helm takes templates plus values, renders them into normal kubernetes yaml. and send those resources to your cluster through the k8s api.
This helps avoid manually maintaining many nearly identical yaml files with different environments.

Basic flow:
- install the helm cli
- add a chart repo
- search for the chart
- install it into your cluster
- customize it with values
- Upgrade or roll back when needed.

Common commands
helm repo add -- add a chart repo
helo repo update -- refresh repo metadata
helm search repo -- find charts in repo
helm install -- install a chart as a release
helm upgrade -- update an existing release
helm rollback -- return to a previous release version
helm list -- show installed releases
helm status -- show release status

-------------------------
SET CUSTOM VALUES:
helm instll my-nginx bitnami/nginx --set service.type=LoadBalancer --et replicaCount=2
or
with a file -- helm install my-nginx bitnami/nginx -f value-prod.yaml


Upgrades or rollback.
helm upgrade my-nginx bitnami/nginx --set replicaCount=3
helm history my-nginx
helm rollback my-nginx 1


helm install my-ingress repo-name/nginx-ingress
#           ^ release name   ^ chart reference (repo/chart)