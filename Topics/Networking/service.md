when you create the service with a selector, k8s watches for pods whosse labels match that selector and populates the endpoints slices object with their ips and ports. If no pods match or the pods ar enot ready, the endpoints list can be empty and the service will have nothing usable to send traffic to.


The real traffic path is:
Service DNS or ClusterIP -> node networking rules via kube-proxy -> one of the IPs in Endpoints -> Pod. So Endpoints are not a “middlebox” carrying traffic; they are the backend address book that kube-proxy reads to decide where packets go

if you wanna give a different clusterip to teh service there is a feature in k8s which allows you do add a new servicecidr without doing changes in the api server,
you make a new servicecidr with the servicecidr object and then you make a service, you have to manaually enter the ip from the new servicecidr inorder for the service to take it and then it will work.