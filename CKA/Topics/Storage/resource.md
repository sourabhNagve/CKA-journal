# allocatable resources and allocated resource,
when you try to calculate the available resource to distribute the pods , you first see the allocatable resource and then substract the allocated resource out of that, because that is taken from the allocatable resource.
and then remaining you distribute between the pods