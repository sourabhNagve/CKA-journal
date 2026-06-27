API Request Components
curl --cacert ca.cert \                    # CA certificate for HTTPS
  -H "Authorization: Bearer $TOKEN" \     # Authentication token
  https://API_SERVER:6443/               # API server endpoint
  api/v1/namespaces/NAMESPACE/pods/      # Resource path

🎓 Advanced Topics to Explore
Projected Volume Tokens: Automatically mounted tokens in pods
OIDC Authentication: Integrating external identity providers
Webhook Token Authentication: Custom authentication mechanisms
Admission Controllers: Enforcing RBAC policies at admission time
Pod Security Admission: Restricting pod capabilities based on security context