# if there are too many problems with the nodes lets say node-01 and its too broken, then you can delete it and join it again to the cluster.
kubeadm reset + kubeadm join
Removes all local Kubernetes state from the node (configs, certs, old kubeconfigs).

Lets the control plane issue fresh, correct credentials during join.

Returns the node to a known-good, “just-provisioned” state, which is exactly what kubeadm is designed for.
In production, this is a standard, accepted pattern for broken nodes.

sudo systemctl stop kubelet
sudo kubeadm reset --force
sudo rm -rf /var/lib/cni /var/lib/kubelet /etc/kubernetes
kubectl delete node node-01          # remove old node object
kubeadm token create --print-join-command
sudo <paste-the-kubeadm-join-command>
sudo systemctl start kubelet