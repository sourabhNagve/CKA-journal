# a deployment has to have 2 pods running but they are not scheduled.
k get pods --- no pods
k get deployment - 0/2 running
k describe deployment name - containers are made
k get -A all 
- this shows that the control-manager pod wasnt running.
journalctl -u kubelet | grep kube-controller-manager
- there is some text mistake in the command of the static pod. corrected it and the pods restarted , the pods are scheduled now