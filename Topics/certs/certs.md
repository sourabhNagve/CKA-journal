colordiff -u /k8s/cert-details-old.txt /k8s/cert-details-new.txt
kubeadm certs renew all
kubeadm certs check-expiration