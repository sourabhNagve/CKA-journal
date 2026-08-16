## Certificate Management

```bash
# Compare old and new certificate details
colordiff -u /k8s/cert-details-old.txt /k8s/cert-details-new.txt

# Renew all certificates
kubeadm certs renew all

# Check certificate expiration
kubeadm certs check-expiration

Quick Reminder
check-expiration → Check certificate expiry
renew all        → Renew all kubeadm-managed certificates
colordiff        → Compare old and new certificate details