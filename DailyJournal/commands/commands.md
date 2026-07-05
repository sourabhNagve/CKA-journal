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