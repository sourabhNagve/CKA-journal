pods with empty dir , when a new rollout happens, or for any reason the older pods gets deleted , all the data in the emptydir also gets deleted, this dir is mainly used to share data between the containers.
shadowing

I accidentally broke DNS in my Kubernetes pod this week with a single line of YAML.

I needed to attach some persistent storage to a deployment, so I quickly mounted a PVC and set the mountPath to /etc. The pod spun up, hit the "Running" state, and looked completely healthy.

But suddenly, the application couldn't talk to any of our internal microservices. Every request started throwing "bad address" or "could not resolve host" network errors.

After shelling into the pod and doing some head-scratching, I realized I had accidentally blinded my own container. I fell into the directory shadowing trap.

Here is what actually happened:
When a pod starts, Kubernetes automatically injects a critical file at /etc/resolv.conf. This is the internal phonebook that tells your container how to use CoreDNS to resolve Kubernetes service names into IP addresses.

But Linux bind mounts don’t merge directories—they overlay them.

By mounting my empty PVC to /etc, the Linux kernel placed my new storage directly over the container's built-in /etc folder. The resolv.conf file was instantly hidden underneath the new mount.

My application was basically waking up in a room with no internet directory. It completely forgot how to translate URLs.

The fix was incredibly simple:

Move the mountPath to a dedicated, safe folder like /data.

If I ever actually need to mount a specific config file into /etc, use the subPath directive in the YAML to mount just that file without covering up the rest of the directory.


