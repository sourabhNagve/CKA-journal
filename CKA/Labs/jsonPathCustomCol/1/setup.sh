#!/bin/bash
set -e

echo "[*] Initializing INC-8442 Environment..."
mkdir -p /tmp/sre_exam && cd /tmp/sre_exam

# 1. etcd-dump.json
cat << 'EOF' > etcd-dump.json
{
  "items": [
    {
      "type": "Opaque",
      "metadata": { "labels": { "criticality": "tier-1" } },
      "data": { "token": "c3VwZXItc2VjcmV0LWZha2U=" }
    },
    {
      "type": "kubernetes.io/tls",
      "metadata": { "labels": { "criticality": "tier-0" } },
      "data": { "token": "d3JvbmctdHlwZQ==" }
    },
    {
      "type": "Opaque",
      "metadata": { "labels": { "criticality": "tier-0" } },
      "data": { "token": "aW5jLTg0NDItZW1lcmdlbmN5LWF1dGgtb3ZlcnJpZGU=" }
    }
  ]
}
EOF

# 2. nodes.json
cat << 'EOF' > nodes.json
{
  "items": [
    {
      "metadata": { "name": "ip-10-0-1-55.ec2.internal" },
      "spec": { "taints": [ { "key": "node.kubernetes.io/disk-pressure", "effect": "NoSchedule" } ] }
    },
    {
      "metadata": { "name": "ip-10-0-2-12.ec2.internal" },
      "spec": { "taints": [ { "key": "node.kubernetes.io/memory-pressure", "effect": "NoSchedule" } ] }
    },
    {
      "metadata": { "name": "ip-10-0-3-99.ec2.internal" },
      "spec": {}
    }
  ]
}
EOF

# 3. audit.log
cat << 'EOF' > audit.log
[2026-08-03T10:00:00Z] PATCH /api/v1/namespaces/default/pods/nginx 429 IP: 192.168.1.55 - user: rogue-admin
[2026-08-03T10:01:00Z] GET /api/v1/nodes 200 IP: 10.0.0.1 - user: system
[2026-08-03T10:02:00Z] PATCH /api/v1/secrets 429 IP: 192.168.1.55 - user: rogue-admin
[2026-08-03T10:03:00Z] PATCH /api/v1/configmaps 429 IP:  10.9.8.7   - user: rogue-admin
[2026-08-03T10:04:00Z] POST /api/v1/deployments 429 IP: 172.16.0.4 - user: system
EOF

# 4. pods.json
cat << 'EOF' > pods.json
{
  "items": [
    {
      "metadata": { "name": "kube-proxy-abc", "namespace": "kube-system" },
      "status": {
        "containerStatuses": [
          { "name": "kube-proxy", "restartCount": 55, "image": "registry.k8s.io/kube-proxy:v1.22.0" }
        ]
      }
    },
    {
      "metadata": { "name": "coredns-xyz", "namespace": "kube-system" },
      "status": {
        "containerStatuses": [
          { "name": "coredns", "restartCount": 10, "image": "registry.k8s.io/coredns:v1.22.0" },
          { "name": "sidecar", "restartCount": 60, "image": "my-sidecar:v1.21" }
        ]
      }
    },
    {
      "metadata": { "name": "nginx-ingress", "namespace": "default" },
      "status": {
        "containerStatuses": [
          { "name": "controller", "restartCount": 100, "image": "ingress:v1.22.0" }
        ]
      }
    }
  ]
}
EOF

# 5. deployments.json
cat << 'EOF' > deployments.json
{
  "items": [
    {
      "metadata": { "name": "app-no-requests" },
      "spec": { "template": { "spec": { "containers": [
        { "name": "nginx", "resources": { "limits": { "cpu": "500m" } } }
      ] } } }
    },
    {
      "metadata": { "name": "app-perfect" },
      "spec": { "template": { "spec": { "containers": [
        { "name": "redis", "resources": { "limits": { "cpu": "1" }, "requests": { "cpu": "500m" } } }
      ] } } }
    },
    {
      "metadata": { "name": "app-no-resources" },
      "spec": { "template": { "spec": { "containers": [ { "name": "busybox" } ] } } }
    }
  ]
}
EOF

echo "[*] Data generation complete. Target directory: /tmp/sre_exam"