
 Q1) 
Context
You are the security engineer for a microservices platform. The application pods in the restricted namespace need controlled outbound access to backend services.

Create a new NetworkPolicy named allow-egress-or-logic in the existing namespace restricted .The NetworkPolicy should    allow outgoing (egress) traffic from Pods in namespace restricted only if all of the following conditions are met:

 - Traffic is destined to Pods with label app=database in namespace data OR traffic is destined to Pods with label       role=cache  in namespace cache
 - Traffic is directed to TCP port 5432
  - DNS must be allowed, but only to kube-dns Pods in the kube-system namespace, and only on UDP/TCP port 53
  - Pods must not be able to send traffic to any other Pods, namespaces, or external destinations
  - Pods that do not send traffic on port 5432 must not be allowed egress access



Q2) Context
You are working 🧑‍💻 on an IoT Sensor API Platform that experiences variable traffic patterns throughout the day. The platform needs to scale automatically based on resource utilization to maintain performance while optimizing costs.

A Deployment named sensor-api is already running in the iot-sys namespace with 12 replicas. The metrics-server has been installed and configured for you.

❓ Question
A Deployment named sensor-api is running in the iot-sys namespace.

You must configure autoscaling for this Deployment by creating an HPA called sensor-hpa that can scale between 2 and 8 replicas.

The HPA should use both CPU and memory utilization, with each metric targeting 80% utilization.

Adding stabilizationWindowSeconds: 5 in the HPA ensures the replicas scale down smoothly from 12 to 2 , since the 12 pods were running unnecessarily without traffic.

Q3)📖 Problem Statement
U.A. High School is deploying a public Hero Registration Portal with two backend services:

/register → register-service on port 80
/verify → verify-service on port 80
The portal must be accessible at: heroes.ua-academy.com

Izuku Midoriya wants all hero data protected with TLS.

Task:

Create an Ingress named hero-reg-ingress in namespace class-1a that:

Uses TLS termination with secret ua-heroes-tls
Routes:
heroes.ua-academy.com/register → register-service
heroes.ua-academy.com/verify → verify-service
Configure the DNS entry in /etc/hosts based on the Ingress LoadBalancer IP
curl -k -v https://heroes.ua-academy.com/register | jq
curl -k -v https://heroes.ua-academy.com/verify | jq

  

Q4)   The Japan Railway (JR) has deployed three microservices in the jp-bullet-train-app-prod namespace:

available - Real-time train availability
books - Booking status
travellers - Passenger manifest
Your task is to expose these services externally using the Kubernetes Gateway API with TLS termination and path-based routing.

Please wait 1 minute for MetalLoadBalancer to set up the gateway.
🎯 Your Tasks:
Task 1: Create the Gateway
Create a Gateway named bullet-train-gateway in namespace jp-bullet-train-gtw with the following specifications:

Name: bullet-train-gateway
Namespace: jp-bullet-train-gtw
GatewayClassName: nginx
Listener Configuration:
Protocol: HTTPS
Port: 443
Hostname: bullet.train.io
TLS Mode: Terminate
TLS Certificate: Reference the existing Secret bullet-train-tls in the same namespace
Note: The TLS secret bullet-train-tls has already been created in the jp-bullet-train-gtw namespace.

Task 2: Create the HTTPRoute
Create an HTTPRoute named bullet-train-route in namespace jp-bullet-train-gtw with path-based routing:

Name: bullet-train-route
Namespace: jp-bullet-train-gtw
Parent Gateway: bullet-train-gateway
Hostname: bullet.train.io
Routes:
Path /available → Service available (port 80) in namespace jp-bullet-train-app-prod
Path /books → Service books (port 80) in namespace jp-bullet-train-app-prod
Path /travellers → Service travellers (port 80) in namespace jp-bullet-train-app-prod
Path Match Type: PathPrefix for all routes
Task 3: Configure Local DNS
To access the services via the domain name bullet.train.io :

Edit the /etc/hosts file
Add an entry mapping bullet.train.io to the Gateway's LoadBalancer IP
Test access to all three endpoints using curl with the -k flag (to skip certificate verification for self-signed cert)
Task 4: Validation Test
Tests all three endpoints:

#!/bin/bash
echo "Testing Available Trains:"
curl -sk https://bullet.train.io/available | jq

echo -e "\nTesting Bookings:"
curl -sk https://bullet.train.io/books | jq

echo -e "\nTesting Travellers:"
curl -sk https://bullet.train.io/travellers | jq