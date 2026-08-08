-o jsonpath="{}"
"{.items[*]}" --- to get all from the list
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
Explanation:

.items[*] is the array of pod objects returned by kubectl get pods.

range .items[*] says: “for each element in this array…”

{.metadata.name} prints the name field of the current element.

{"\n"} adds a newline after each name.

end finishes the loop.also fo