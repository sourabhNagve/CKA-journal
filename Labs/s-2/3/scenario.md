# 1. Exam Scenario

Task:
A highly secure application named `crypto-service` has been deployed in the `secure-enclave` namespace. It consists of an `api` container and a `key-loader` sidecar container. 

The security team enforces strict pod security standards. However, the current deployment is completely broken. It fails to start, the sidecar is crashing, the health checks are failing, and the Service is routing no traffic.

Troubleshoot and resolve all issues in sequence so the application becomes fully operational.

When fully operational:
1. The `crypto-service` pod must have both containers in the `Running` and `Ready` state.
2. The `key-loader` container must successfully locate its keys and log `Key loaded successfully`.
3. The `crypto-svc` Service must successfully route traffic to the pod.

# 2. Initial Cluster State

- **Namespaces:** `secure-enclave`
- **Deployments:** `crypto-service` (in `secure-enclave`)
- **Services:** `crypto-svc` (in `secure-enclave`)
- **Secrets:** `crypto-keys` (in `secure-enclave`)

# 6. Expected kubectl Outputs

**Command:** `kubectl get pods -n secure-enclave`
```text
NAME                              READY   STATUS                       RESTARTS   AGE
crypto-service-7d8b5c8f49-abcde   0/2     CreateContainerConfigError   0          2m

Command: kubectl describe pod -n secure-enclave -l app=crypto-service

Plaintext
...
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Warning  Failed     12s (x6 over 2m)   kubelet            Error: container has runAsNonRoot and image will run as root (pod: "crypto-service-7d8b5c8f49-abcde_secure-enclave", container: api)
(Note: Once you fix the security context issue, the containers will attempt to start. The sidecar will then enter CrashLoopBackOff due to missing files, and the api container will fail its readiness probe. Finally, the Service will need its endpoint routing fixed).

7. Difficulty
9/10

8. Skills Tested
Pod SecurityContexts (runAsNonRoot, runAsUser)

Multi-container Pod Troubleshooting

Secret Volume Mounts

Liveness/Readiness Probes

Service Selectors and Endpoints

9. Constraints
Do NOT remove runAsNonRoot: true from the Pod's SecurityContext. You must satisfy this constraint by ensuring the containers run as a non-root user (e.g., UID 1000).

Do NOT change the commands executed by the containers.

Do NOT recreate the crypto-keys Secret.

Do NOT delete the crypto-service deployment; modify it in place.

The crypto-svc must retain its current port configurations.

10. Time Estimate
15 - 20 minutes