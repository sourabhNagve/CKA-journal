# DNS Troubleshooting

I created a ReplicaSet and tried to resolve the Kubernetes service from inside the Pod:

    nslookup kubernetes.default

It failed, indicating a possible DNS issue.

I then checked:

    ping <kubernetes-service-ip>

This also failed.

And:

    curl <service-name>

The service name was not resolving either.

## Troubleshooting Steps

First, check whether the CoreDNS Pods are running:

    kubectl get pods -n kube-system -l k8s-app=kube-dns

Check the CoreDNS Service:

    kubectl get svc -n kube-system kube-dns

Check whether the Service has endpoints:

    kubectl get endpoints -n kube-system kube-dns

Check CoreDNS logs:

    kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

## Root Cause

The CoreDNS Pods were healthy, the `kube-dns` Service existed, and the CoreDNS configuration was correct.

The problem was that the `kube-dns` Service had **no endpoints**.

The Service had incorrect labels/selectors, so it was not selecting the CoreDNS Pods.

After correcting the labels, the endpoints appeared and DNS resolution started working again.

## Key Lesson

A DNS issue does not always mean CoreDNS itself is broken.

Check the full path:

    Pod
      ↓
    kube-dns Service
      ↓
    Endpoints
      ↓
    CoreDNS Pods

If the `kube-dns` Service has no endpoints, DNS requests cannot reach CoreDNS.