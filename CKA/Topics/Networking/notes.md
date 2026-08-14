API Request Components
curl --cacert ca.cert \                    # CA certificate for HTTPS
  -H "Authorization: Bearer $TOKEN" \     # Authentication token
  https://API_SERVER:6443/               # API server endpoint
  api/v1/namespaces/NAMESPACE/pods/      # Resource path
