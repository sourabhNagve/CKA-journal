# Add the tracking annotations
kubectl annotate configmap dash-frontend-config -n monitoring meta.helm.sh/release-name=dash-frontend
kubectl annotate configmap dash-frontend-config -n monitoring meta.helm.sh/release-namespace=monitoring

# Add the managed-by label
kubectl label configmap dash-frontend-config -n monitoring app.kubernetes.io/managed-by=Helm