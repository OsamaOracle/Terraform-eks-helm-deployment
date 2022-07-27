# Terraform-eks-helm-deployment
Sample code to deploy EKS plus a helm using terraform

##### This code will create the following resource on AWS:-
- VPC.
- Subnet (Public subnet,private subnet).
- nat gateway
- EKS cluster
- ECR Private repo.

##### EKS Features:-
- AutoScaler enabled.
- One worker node in private subnet, One worker node in public subnet.

##### Code purpose

Deploy application under AWS account using helm chart, everything automated using terraform.

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

##### Note

- Terraform will fail for the first time once it will try to deploy the code, this is because the ECR created but the image not build yet, you need to access to AWS account --> ECR then choose the repo and view the push command and run them manually.
- copy ECR ARN and Paste it under value.yaml which is located under challenge directory.

