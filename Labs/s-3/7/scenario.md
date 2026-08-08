not done
# 1. Exam Scenario

Task:
A critical kernel patch must be applied to the worker node (or the single control-plane node if in a test environment) you are currently logged into. 

However, a junior admin attempted to manually tune the `kubelet` configuration on this node just before the maintenance window, and now the node has fallen into a `NotReady` state. The `kubelet` service is continuously crashing.

Additionally, once the node is back online, it needs to be safely evacuated for the kernel patch, but strict high-availability policies are in place.

Troubleshoot and resolve the issues sequentially:
1. Identify the misconfiguration in the `kubelet` configuration file on this node, fix it, and restore the node to the `Ready` state.
2. Safely `drain` the node to prepare for maintenance, ensuring you ignore DaemonSets.
3. You will find that the drain command hangs indefinitely. Troubleshoot the cluster-level high-availability constraints blocking the eviction. You must satisfy the policy (e.g., by scaling the application) so the drain successfully completes.

When fully operational:
1. The node must be in the `Ready,SchedulingDisabled` state.
2. The `web-store` application in the `e-commerce` namespace must be successfully evicted from the node.

# 2. Initial Cluster State

- **Namespaces:** `e-commerce`
- **Deployments:** `web-store` (in `e-commerce`)
- **PodDisruptionBudgets (PDB):** `web-store-pdb` (in `e-commerce`)
- **Node State:** `NotReady`

# 6. Expected kubectl Outputs

**Command:** `systemctl status kubelet`
```text
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/lib/systemd/system/kubelet.service; enabled; vendor preset: enabled)
  Drop-In: /etc/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: activating (auto-restart) (Result: exit-code) 
...

Command: journalctl -u kubelet | tail -n 5

Plaintext
Failed to load kubelet config file: strict decoding error: unknown field "tlsCipherSuitess"
(Note: Once you fix the kubelet and attempt to run kubectl drain <node>, you will see an error regarding PodDisruptionBudgets preventing the eviction. You must scale the application to safely allow the eviction).  

7. Difficulty  
10/10  

8. Skills Tested  
Node-level Troubleshooting (kubelet, systemd, journalctl)  

Kubelet Configuration (/var/lib/kubelet/config.yaml)  

Node Maintenance (cordon and drain)  

PodDisruptionBudgets (PDB) and High Availability  

9. Constraints  
This lab MUST be executed on a kubeadm provisioned node (works on both control-plane or worker nodes). You need root / sudo access.

Do NOT delete the web-store-pdb PodDisruptionBudget.

The web-store-pdb dictates that minAvailable must be 2. You are allowed to scale the web-store deployment to 3 replicas so that 2 remain available while the 3rd is evicted during the drain.

Leave the node cordoned (SchedulingDisabled) at the end of the exercise.

10. Time Estimate
20 - 25 minutes