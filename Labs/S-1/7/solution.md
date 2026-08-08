The script tries to create a file (touch /data/test) but gets rejected.
By default, when Kubernetes creates a temporary storage volume (emptyDir), it assigns ownership of that folder to the root user. However, your pod is specifically configured with runAsUser: 1000, meaning it is acting as a regular, non-root user. A regular user isn't allowed to write to a root-owned folder.
The Fix (fsGroup): We need to tell Kubernetes to change the ownership of that volume so our non-root user can use it. Adding fsGroup: 1000 to the pod's securityContext tells Kubernetes, "Change the group ownership of any mounted volumes to group 1000 before the container starts."

The pod is configured to run as user 1000 (runAsUser: 1000), but the emptyDir volume mounted at /data is owned by root by default. Because no fsGroup is specified, the container lacks permission to write to the mount path.
ADD fsGroup: 100 to the pod securityContext.
This tells kubernetes to change teh ownership of the volume so that processes belonging to group 1000 can read and write to it.
-----------------------------------
Once the pod can finally write to the folder, it tries to create a 60-megabyte file. Suddenly, the pod crashes and restarts with an OOMKilled (Out of Memory) error.
The "Why": If you look at the volume configuration at the bottom of the deployment, it says emptyDir: medium: Memory. This means /data isn't a normal hard drive folder; it is a "RAM disk" (tmpfs). Because it lives entirely in RAM, any file written to /data counts directly against the container's memory limit. The container is strictly limited to 40MB (40Mi), so forcing it to hold a 60MB file in its RAM instantly blows past the limit and Kubernetes kills it.
The Fix: We must increase the container's memory limit in the resources section to something larger than 60MB (like 128Mi) so it has enough room for both the script and the 60MB file.

-----------------------------------------
