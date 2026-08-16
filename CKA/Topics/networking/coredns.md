i got a problem,made a replicaset and tried to lookup the kubernetes service from inside the pod, but it wasnt working.
- nslookup kubernetes.default
it didnt work, so there is problem with the dns
- ping <kubernetes service ip>
it didnt work again the same 
- curl <service name> (service name wasnt resolving)
none of them worked, 
so i checked the coredns pods were fine, the kubedns service was fine.
corefile was okay
still the issue
now whether the kubedns service  didnt have any endpoints , there was wrong labels in the service file of the kubedns service.
corrected it and the endpoints were there again and the problem got solved.

kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get svc -n kube-system kube-dns
kubectl get endpoints -n kube-system kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50