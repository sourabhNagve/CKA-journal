# NetworkPolicy

We use a **deny-all Ingress and Egress NetworkPolicy** as the default security boundary, then add explicit allow rules for the traffic the application actually needs.

By default, Pods are **non-isolated** for both ingress and egress, so traffic is allowed unless a NetworkPolicy selects the Pod and restricts that direction.

- If a Pod is selected by an **Ingress** policy, only ingress becomes restricted.
- Egress remains open unless an **Egress** policy also applies.
- Once a direction is isolated, only traffic explicitly allowed by the policy is permitted.

## namespaceSelector + podSelector

When `namespaceSelector` and `podSelector` are in the **same list item**, they work as **AND**:

    from:
      - namespaceSelector:
          matchLabels:
            name: frontend
        podSelector:
          matchLabels:
            app: frontend

Allows:

    Pods in the frontend namespace
    AND
    Pods with app=frontend

When they are **separate list items**, they work as **OR**:

    from:
      - namespaceSelector:
          matchLabels:
            name: frontend
      - podSelector:
          matchLabels:
            app: frontend

Allows:

    Any Pod in the frontend namespace
    OR
    Any Pod with app=frontend in any namespace