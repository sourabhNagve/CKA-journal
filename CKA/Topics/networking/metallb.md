kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml
kubectl get pods -n metallb-system --watch
kubectl get nodes -o wide  
- MetalLB needs a pool of IP addresses to hand out. For this to work smoothly in KillerCoda, those IPs should be in the same network range as your Kubernetes nodes. Look at the INTERNAL-IP column. It will likely be something like 172.30.1.2 or 192.168.0.8.


------------------
In order to assign an IP to the services, MetalLB must be instructed to do so via the IPAddressPool CR.

All the IPs allocated via IPAddressPools contribute to the pool of IPs that MetalLB uses to assign IPs to services.

apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.10.0/24
  - 192.168.9.1-192.168.9.5
  - fc00:f853:0ccd:e799::/124
or 

apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
------------------------------------

  apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
Setting no IPAddressPool selector in an L2Advertisement instance is interpreted as that instance being associated to all the IPAddressPools available.

So in case there are specialized IPAddressPools, and only some of them must be advertised via L2, the list of IPAddressPools we want to advertise the IPs from must be declared (alternative, a label selector can be used).

apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
  -------------------------------