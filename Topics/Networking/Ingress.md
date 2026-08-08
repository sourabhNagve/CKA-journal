# Ingress Controller
- a k8s component (usually nginx) that acts as the entry point for external traffic
- runs as pod or deployment in cluster.
it recieves https request from the user
read host and path from the request
loks for ingress resource that matches

# TLS termination

TLS Termination:

Ingress decrypts HTTPS traffic
Forwards HTTP to backend services
Services don't need TLS certificates


a kubernetes secret containing tls cert and private key.
What happens:
Before TLS Termination:
  HTTPS (encrypted) → User → Ingress
After TLS Termination:
  HTTP (decrypted) → Ingress → Backend
Process:
Ingress controller uses the certificate from ua-heroes-tls secret
Decrypts the HTTPS request
Now has plain HTTP: GET /register
Backend services receive unencrypted HTTP (simpler for them)
Why do this?
Backend pods don't need to handle TLS certificates
Ingress handles all security centrally
Backend apps stay simple (just HTTP)



Note*  ingress class is cluster scoped
ingress is namespaced


curl -k -v https://heroes.ua-academy.com/register | jq