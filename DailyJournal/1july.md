k config get-contexts --kubeconfig=/opt/course/1/kubeconfig -o name
 k config view --kubeconfig /opt/course/1/kubeconfig -o jsonpath='{.users[?(@.name == "account-0027")].user.client-certificate-data}' --raw | base64 -d 

 ------------------------
 if any certificate is deleted mistakenly
.- sudo kubeadm init phase certs apiserver
- sudo systemctl restart kubelet.service
- 
----------------
resource quota is namespace scoped.
 a quota is just a limit set on how much a namespace can use.
It stops one app or team from consuming too many CPU, memory, storage, or object resources in the namespace
It helps keep the cluster fair, stable, and predictable for everyone sharing it