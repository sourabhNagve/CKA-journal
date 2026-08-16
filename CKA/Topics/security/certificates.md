# Kubernetes Users and Certificates

Kubernetes does not typically create users as Linux does. **Users are not stored as Kubernetes objects.**

Instead:

- A user is authenticated through an external identity mechanism.
- One common method is **client certificates**.
- The username can come from the certificate subject, such as the `Common Name (CN)`.
- Authorization is then handled by **RBAC** using Roles and RoleBindings.

## Create a Kubernetes User with a Client Certificate

The general process is:

    Generate private key
          ↓
    Generate CSR
          ↓
    Get CSR signed by a trusted CA
          ↓
    Add certificate to kubeconfig
          ↓
    Grant permissions using RBAC

### 1. Generate the Private Key

    openssl genrsa -out alice.key 2048

### 2. Generate the CSR

    openssl req -new -key alice.key -out alice.csr -subj "/CN=alice/O=devs"

`CN=alice` → username  
`O=devs` → group

### 3. Create a Kubernetes CertificateSigningRequest

Encode the CSR:

    cat alice.csr | base64 -w 0

Create `alice-csr.yaml`:

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

Apply and approve it:

    kubectl apply -f alice-csr.yaml
    kubectl certificate approve alice

### 4. Retrieve the Signed Certificate

    kubectl get csr alice \
      -o jsonpath='{.status.certificate}' | base64 --decode > alice.crt

Check the certificate:

    openssl x509 -in alice.crt -text -noout

## Use the Certificate

You can authenticate directly using:

    kubectl \
      --certificate-authority=ca.crt \
      --client-certificate=alice.crt \
      --client-key=alice.key \
      get pods

Or add the credentials to kubeconfig:

    kubectl config set-credentials alice \
      --client-certificate=alice.crt \
      --client-key=alice.key

    kubectl config set-context alice-context \
      --cluster=kubernetes \
      --user=alice

    kubectl config use-context alice-context

After authentication, use **RBAC** to grant Alice permissions.

---

# Kubernetes Certificate Management

Check certificate expiration:

    kubeadm certs check-expiration

Renew Kubernetes certificates:

    kubeadm certs renew all

Restart kubelet when required:

    sudo systemctl restart kubelet

**Note:** If the Kubernetes CA itself is renewed, the certificates signed by that CA also need to be renewed/reissued.

## Inspect a Certificate

    openssl x509 -noout -text -in server.crt

Inspect a CSR:

    openssl req -noout -text -in server.csr

Generate a private key:

    openssl genrsa -out server.key 2048

Generate a CSR:

    openssl req -new -key server.key -out server.csr

### File Extensions

    .key       → Private key
    .crt/.pem  → Certificate
    .pub       → Public key

---

# Useful Kubeconfig Commands

List contexts from a specific kubeconfig:

    kubectl config get-contexts \
      --kubeconfig=/opt/course/1/kubeconfig \
      -o name

Extract a user's client certificate from kubeconfig:

    kubectl config view \
      --kubeconfig=/opt/course/1/kubeconfig \
      -o jsonpath='{.users[?(@.name == "account-0027")].user.client-certificate-data}' \
      --raw | base64 -d

---

# Regenerate a Deleted API Server Certificate

If the API server certificate is accidentally deleted:

    sudo kubeadm init phase certs apiserver

This regenerates the API server certificate and key for the existing control-plane node without reinitializing the entire cluster.

Then restart kubelet:

    sudo systemctl restart kubelet.service

---

# cert-manager

**cert-manager** is a Kubernetes operator that automates TLS certificate management.

It extends Kubernetes with CRDs that allow you to declaratively define:

- Certificates
- Issuers
- ClusterIssuers
- Certificate-related configuration

It can automatically request, renew, and manage certificates.