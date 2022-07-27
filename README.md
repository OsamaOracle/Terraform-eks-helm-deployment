# Terraform-eks-helm-deployment
Sample code to deploy EKS plus a helm using terraform

##### This code will deploy the following resource on AWS:-
- VPC.
- Subnet (Public subnet,private subnet).
- nat gateway
- EKS cluster

##### EKS Features:-
- AutoScaler enabled.
- One worker node in private subnet, One worker node in public subnet.

##### Run the code:-

```
terraform init
terraform plan 
terraform approve --auto-approve
```

##### Delete the resource

```
terraform destroy --auto-approve
```
