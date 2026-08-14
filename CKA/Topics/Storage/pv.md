# in order to put the pvin the certain node you need to add the nodeaffinity to that pv yaml
nodeAffinity:
  required:
    nodeSelectorTerms:
    - matchExpressions:
      - key: kubernetes.io/hostname
        operator: In
        values:
        - node01

# use of volumeName
usually uou do not need to write volumeName in the PVC, k8s can bind the pvc to any matching pv automatically so volumeName is only needed when you want to force a specific pv.
why volumeName exits:
it supports manual or explicit binding to one exact pv
it is usefull when you already know which disk or path you want, such as resuing existing data.
without it k8s just matches on storage class,size access mode and other rules.
Normal case
Most of the time, you leave volumeName out, and Kubernetes handles the binding for you. That keeps PVCs portable and lets dynamic provisioning work smoothly.

# pvc storage is mutable
pvc storage is mutable, the value can be changed with the edit command.

# when you manually bind the pvc to pv , you have to mention the "volumeName" field inside the pvc (pv name).
# default is immediate



When a PVC is deleted but the PV has persistentVolumeReclaimPolicy: Retain , the PV enters a "Released" state and cannot be claimed by a new PVC because it still references the old claim.(you have to delete the claimref inorder to make it available)
Step 1: Deployment Deleted
├─ Pod terminates
├─ Volume unmounted from Pod
└─ PVC remains bound (no change)

Step 2: PVC Deleted
├─ PVC removed from cluster
├─ PV behavior depends on ReclaimPolicy:
│   ├─ Retain → PV status: Released (data intact)
│   ├─ Delete → PV and storage deleted automatically
│   └─ Recycle → PV scrubbed (deprecated)
└─ If Retain: PV still exists with data

Step 3: PV Deleted (manual, only if Retain policy)
├─ PV resource removed from cluster
└─ Underlying storage cleanup (manual if hostPath/NFS).

Why This Order Matters:
Attempting to delete PVC first (while Pod is using it) → PVC enters Terminating state indefinitely
Attempting to delete PV first (while PVC is bound) → PV enters Terminating state indefinitely
Protection mechanism: Kubernetes prevents accidental data loss by blocking deletion of in-use resources