in this question we dont have a repo added
we have the charts available at /opt/helm-charts/payment-gateway.

so in this way, the template is the placeholders and values.yaml is the place where we provide the values from.
if the value is hardcoded in teh template you need to directly change otherwise use the values.yaml


when you set the values through --set, you get the output with helm get values or helm show values
but if you have the values.yaml locally and you make the changes then there it wont be there, though  the changes will happen.