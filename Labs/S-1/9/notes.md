a deployment running with 3 pods, you see it also creates a rs with 3 desired pods.
 when you make changes to the deployment, you can see another rs is created, this happens because of hte rolling update behaviour, 
 k8s creates a new rs for the new version and keeps hte old one around for rollback.

best way to put your changes to situation where older rs pods are crashloop off or any other issue, and that rs wont let new pods to be scheduled then its better to scale the deployment to 0 and then scale it again, instead of deleting the rs manually.
 