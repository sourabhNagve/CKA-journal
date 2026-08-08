The Scenario:
Your security team has mandated a strict zero-trust network topology. The cluster is divided into three namespaces: sec-front, sec-back, and sec-db. Currently, default-deny policies are applied everywhere, causing total application failure.

Your task is to craft exact NetworkPolicy resources (using networking.k8s.io/v1) to allow ONLY the required flow of traffic, while strictly maintaining the default-deny rules.

Maintain the existing Default-Deny (Ingress & Egress) policies in all three namespaces.

Allow Ingress traffic from pods in the ingress-nginx namespace to the frontend pods in sec-front on TCP port 80.

Allow Egress from frontend (in sec-front) to backend pods (in sec-back) strictly on TCP port 8080. Allow corresponding Ingress on the backend.

Allow Egress from backend (in sec-back) to database pods (in sec-db) strictly on TCP port 5432. Allow corresponding Ingress on the database.

Trap warning: You must ensure namespace labels are properly targeted (e.g., matching by kubernetes.io/metadata.name). DNS resolution (UDP 53 egress) must also be permitted for sec-front and sec-back to kube-system so they can resolve service names.