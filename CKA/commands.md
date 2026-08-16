# Useful Commands & Exam Notes

## grep commands

grep "error" logs.txt
grep -i "error" logs.txt
grep -r "error" /var/logs/

- -i → case-insensitive search
- -r → recursive search
- -E → extended regular expressions
- egrep is the older equivalent of grep -E

Examples:
grep "a\+" file.txt
grep -E "a+" file.txt

Prefer grep -E over egrep.

--------------------------------------------------

## Kubernetes Logs

kubectl logs multi-app -c app -n logs --previous --tail=100

- --previous → logs from the previous container instance
- --tail=100 → shows the last 100 lines

Redirect both stdout and stderr:

kubectl logs <pod> > file.txt 2>&1

--------------------------------------------------

## Shell Commands in Containers

Use sh -c when shell features such as variable expansion and && are required:

command: ["sh", "-c", "echo $KEY && sleep 3600"]

Kubernetes also supports $(VAR_NAME) expansion in command and args:

command: ["sh", "-c", "echo $(KEY) && sleep 3600"]

--------------------------------------------------

## Find the Highest CPU Pod

kubectl top pod -A --sort-by=cpu --no-headers | head -1 | awk '{print $2 "," $1}' > high_cpu_pod.txt

- --no-headers → removes the header
- head -1 → selects the first result
- awk → extracts CPU and Pod name

--------------------------------------------------

## Ingress Annotation

annotations:
  nginx.ingress.kubernetes.io/ssl-redirect: "false"

--------------------------------------------------

## Sort Pod IP Addresses

echo "IP_ADDRESS" > pod_ips.txt
kubectl get pods -o wide --no-headers | awk '{print $6}' | sort -t . -k1,1n -k2,2n -k3,3n -k4,4n >> pod_ips.txt

--------------------------------------------------

## Static Pod on a Worker Node

Static Pods are managed directly by the kubelet on the node.

SSH into the worker node and place the Pod manifest in the kubelet's static Pod directory, commonly:

/etc/kubernetes/manifests

Example manifest:

apiVersion: v1
kind: Pod
metadata:
  name: static-nginx
spec:
  containers:
    - name: nginx
      image: nginx

The kubelet automatically detects the manifest and starts the Pod.

- Static Pods are tied to the node where the manifest exists.
- Removing the manifest causes the kubelet to remove the Pod.
- Deleting the Pod with kubectl does not permanently remove it while the manifest exists.
- To run the same Static Pod on another node, place the manifest on that node.
- The static Pod directory is configurable through the kubelet configuration.

--------------------------------------------------

## Netcat Port Check

nc -z -w 2 192.168.1.10 8080

- nc → netcat
- -z → check the port without sending data
- -w 2 → 2-second timeout

Useful for quickly checking whether a TCP port is reachable.

--------------------------------------------------

## Copy Files with kubectl

Local → Pod:

kubectl cp nginx web:/path -c server

Pod → Local:

kubectl cp ns/web:/filelocation .

--------------------------------------------------

## Debug a Pod

kubectl debug -it pod/web-server --privileged

--------------------------------------------------

## kubectl explain

Display nested fields:

kubectl explain certificate.spec --recursive

- --recursive → shows nested fields under the specified resource field.