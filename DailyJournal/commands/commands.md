# grep commands
grep "error" logs.txt # is case sensitive
grep -i "error" logs.txt # is case insensitive
grep -r "error" /var/logs/ # search recursively in a directory

cat file.txt | grep "pattern" # search for a pattern in a file
cat file.txt | grep -i "pattern" # search for a pattern in a file, case insensitive

egrep "pattern" file.txt # search for a pattern in a file
egrep -i "pattern" file.txt # search for a pattern in a file, case insensitive
egrep -r "pattern" /var/logs/ # search recursively in a directory
egrep -i "pattern" /var/logs/ # search recursively in a directory, case insensitive

# difference between grep and egrep
# egrep is the same as grep -E, which allows for extended regular expressions.
# we dont need to escape special characters like +, ?, |, and () in egrep, while we do in grep.
# example:
grep "a\+" file.txt # search for one or more occurrences of 'a' in a file
egrep "a+" file.txt # search for one or more occurrences of 'a' in a file, no need to escape the '+'

# also difference between grep and egrep is that egrep is faster than grep for large files, because it uses a different algorithm for searching.  
# Difference between grep in the beginning and grep in the middle of a pipeline is that grep in the beginning reads the entire file into memory, while grep in the middle of a pipeline reads the input line by line. 
# so if you are searching for a pattern in a large file, it is better to use grep in the middle of a pipeline, because it will use less memory. 
# and if you are searching for a pattern in a small file, it is better to use grep in the beginning, because it will be faster. 

-------------------------------------------------
kubectl logs multi-app -c app -n logs --previous --tail=100
It shows the last 100 lines of logs from the previous instance of the app container inside the multi-app Pod in the logs namespace. The --previous flag is useful when the container restarted and you want to see the logs from the crashed run.

--------------------------------
# check control plane certificate expiry
kubeadm certs check-expiration
# renew all certs(if expiring)
kubeadm certs renew all


-----------------------------------
k get logs > file.txt 2>&1  (this will give stderr and stdout both)

-----------------------------------
command: ["sh", "-c", "echo $KEY && sleep 3600"] works because sh -c makes the shell expand $KEY and understand &&.

command: ["sh", "-c", "echo $KEY && sleep 3600"] without extra quotes in YAML still works because YAML treats it as the same string value.

command: ["sh", "-c", "echo $(KEY) && sleep 3600"] can work because Kubernetes expands $(KEY) before the container starts, using the value from env:.

echo "$(KEY)" && sleep 3600 also works for the same reason, and the quotes just preserve the value as one string.



-------------------------------------
kubectl top pod -A --sort-by=cpu --no-headers | head -1 | awk '{print $2 "," $1}' > high_cpu_pod.txt
--no-headers = the header line will be removed
head -1 = will give first line of the output
--------------------------------------
annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
-------------------------------------
    echo "IP_ADDRESS" > pod_ips.txt
kubectl get pods -o wide --no-headers | awk '{print $6}' | sort -t . -k1,1n -k2,2n -k3,3n -k4,4n >> pod_ips.txt