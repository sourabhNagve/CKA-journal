We use a deny-all ingress and egress NetworkPolicy as the default security boundary, then add explicit allow rules for the traffic the application actually needs.

from:
- namespaceSelector:
    matchLabels:
      name: frontend
  podSelector:              # Same indentation = AND
    matchLabels:
      app: frontend

# Allows: Pods in frontend namespace AND with app=frontend

from:
- namespaceSelector:
    matchLabels:
      name: frontend
- podSelector:              # Separate item = OR
    matchLabels:
      app: frontend

# Allows: Any pod in frontend namespace OR any pod with app=frontend in any namespace

*By default pods are non isolated for both ingress and egress, so all traffic is allowed unless  policy selects them and restricts that direction.
*i f a pod is selected by ingress then only ingress becomes restricted, egress still stays open unless egress policy also applies.


  We use a deny-all ingress and egress NetworkPolicy as the default security boundary, then add explicit allow rules for the traffic the application actually needs.
