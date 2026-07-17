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