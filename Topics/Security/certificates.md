Kubernetes does not typically support creating users as in Linux. Instead, users are not stored as in-cluster objects. A user is authenticated through an external identity mechanism, and one common method is to use client certificates. Access is then authorized through RBAC.

The username is usually taken from the certificate subject, such as the Common Name. The certificate identifies the user to the API server. Authorization is controlled by Roles and RoleBindings, not by a Kubernetes user record, because Kubernetes does not maintain one.

Q create a k8s user
- generate a key and cert request using openssl commands
- get the certificate signed by a trusted CA (in k8s we use the certificate signing request object mostly)
- put that cert into the kubeconfig
- and attach the RBAC rules to the permission

Example: creating a client certificate for alice
# generate the private key 
openssl genrsa -out alice.key 2048
# get the csr file
openssl req -new -key alice.key -out alice.csr -subj "/CN=alice/O=devs"
# You can also create a Kubernetes CSR object using the base64-encoded contents of alice.csr

cat alice.csr | base64 -w 0 

apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: alice
spec:
  request: <base64-encoded-csr-content>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - client auth

#
kubectl apply -f alice-csr.yaml
kubectl certificate approve alice

# retrieve the signed cert
kubectl get csr alice -o jsonpath='{.status.certificate}' | base64 --decode > alice.crt

# check the certificate using:
openssl x509 -in alice.crt -text -noout

# Using the certificate
# To authenticate to the API server with the certificate:
kubectl --certificate-authority=ca.crt --client-certificate=alice.crt --client-key=alice.key get pods

# To add this to the kubeconfig:
kubectl config set-credentials alice --client-certificate=alice.crt --client-key=alice.key
kubectl config set-context alice-context --cluster=kubernetes --user=alice
kubectl config use-context alice-context



-------------------------------------------------------

kubeadm certs check-expiration
kubeadm certs renew all
sudo systemctl restart kubelet (to let the cluster use the new updated certificates) 

Note: if you renew the CA you must renew all the other certificates.

