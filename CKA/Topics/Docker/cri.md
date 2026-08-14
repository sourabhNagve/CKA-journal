# Before the CRI got introduced
docker engine only supported runtime for kubernetes
kubelet had docker specific code built in.

inside kubelet there was docker manager which-
- connect to docker own socket(/var/run/docker.sock
- call docker http api (example: create container, start container

flow:
kubelet ---> internal docker client code ----> docker engine
That internal code knew Docker’s API format directly.

This led to:

Tight coupling: kubelet “knows” Docker internals.

Hard to add/maintain multiple runtimes.

Why this changed
When other runtimes appeared (containerd, CRI‑O, etc.):

Each had its own API and behavior.

Adding support for each one inside kubelet became painful and didn’t scale.

So Kubernetes introduced the Container Runtime Interface (CRI) – a single, standard gRPC API that kubelet uses for all runtimes



# After CRI
kublet no longer directly calls docker api
kubelet calls only the cri methods over a socket

NEW FLOW:
Kubernetes Control Plane → kubelet → CRI (Container Runtime Interface) → cri-dockerd (adapter) → Docker Engine (containerd + runc) → containers.

there the adapter(cri-dockerd) is the bridge between the cri calls and the docker api calls.
