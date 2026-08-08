# 1. Exam Scenario

Task:
A deployment named `payment-gateway` exists in the `app-prod` namespace. It is critical for processing transactions but is currently entirely down.

Troubleshoot and resolve all issues preventing the `payment-gateway` from running. You will need to resolve issues at the cluster-level, identity-level, and pod-configuration level in sequence.

1. The deployment is unable to create any pods due to a cluster-level configuration left behind by a defunct security tool.
2. Once the cluster allows pod creation, the pods fail to schedule due to missing identity resources.
3. The application container requires a certificate file to be mounted exactly at `/certs/tls.crt` to start successfully. However, the provided Secret uses different key names and is currently misconfigured.

When fully operational, exactly 1 `payment-gateway` pod should be in the `Running` state and its logs should display `Cert found, starting...`.

# 2. Initial Cluster State

- **Namespaces:** `app-prod`, `security-tools`
- **Deployments:** `payment-gateway` (in `app-prod`)
- **Secrets:** `gateway-certs` (in `app-prod`)
- **ValidatingWebhookConfigurations:** `shield-webhook.acme.com`

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n app-prod`
```text
No resources found in app-prod namespace.

Command: kubectl describe rs -n app-prod

Plaintext
...
Events:
  Type     Reason        Age                 From                   Message
  ----     ------        ----                ----                   -------
  Warning  FailedCreate  15s (x10 over 45s)  replicaset-controller  Error creating: Internal error occurred: failed calling webhook "validate.shield.acme.com": failed to call webhook: Post "[https://shield-svc.security-tools.svc:443/validate?timeout=10s](https://shield-svc.security-tools.svc:443/validate?timeout=10s)": dial tcp: lookup shield-svc.security-tools.svc on 10.96.0.10:53: no such host
(Note: Once you resolve the webhook issue, you will see FailedCreate events regarding a missing ServiceAccount. Once that is fixed, the pod will spawn but enter CreateContainerConfigError or CrashLoopBackOff until the Secret mounting is fixed).

7. Difficulty
10/10

8. Skills Tested
Admission Controllers (Validating Webhooks)

ServiceAccounts

Secret Projection and Specific Key-to-Path Mapping (items)

System-level Troubleshooting

9. Constraints
Do NOT remove the shield: enabled label from the app-prod namespace.

You are permitted to delete defunct cluster-scoped Admission Controllers if they point to non-existent services.

Do NOT modify or recreate the gateway-certs Secret. You must map the keys correctly inside the Deployment's Pod spec.

Do NOT delete the payment-gateway Deployment; modify it in place.