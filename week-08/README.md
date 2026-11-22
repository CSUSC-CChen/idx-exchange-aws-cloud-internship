# Week 8: Infrastructure as Code

This week I rebuilt the Week 5 VPC with Terraform instead of the console. The code in `main.tf` uses the `terraform-aws-modules/vpc/aws` module (version 5.8.1) to create `training-vpc-tf` with CIDR `10.1.0.0/16`, two public subnets, two private subnets across `us-east-1a` and `us-east-1b`, and a single NAT gateway.

## Declarative vs imperative

Terraform is declarative. I describe the end state I want in `main.tf`, and Terraform works out which API calls to make to get there. The console and AWS CLI are imperative. I run each step myself in the right order, such as creating the VPC, then the subnets, then the route tables, then the associations.

## What each command does

**`terraform init`**
Prepares the working directory. It downloads the AWS provider and the VPC module into `.terraform/`.

**`terraform plan`**
Compares the code with the state file and with what actually exists in AWS, then shows what it would add, change, or destroy. It does not change anything. This is the safety check, so I read the whole plan before applying.

**`terraform apply`**
Runs the plan after I type `yes`. It creates or updates the resources and records them in the state file. My apply ended with `Apply complete! Resources: 19 added, 0 changed, 0 destroyed.` The NAT gateway took the longest (1m55s). Everything else finished in a few seconds.

**`terraform destroy`**
Deletes every resource listed in the state file after I type `yes`. I ran it right after the lab so the NAT gateway and Elastic IP would stop billing.

## Why state matters

The state file (`terraform.tfstate`) is how Terraform maps each block in my code to a real resource ID in AWS. Without it, Terraform has no record of what it created, so it cannot update or destroy those resources correctly. It might also try to create duplicates.

After apply, `terraform state list` showed 19 resources, matching the apply output:

```
module.vpc.aws_default_network_acl.this[0]
module.vpc.aws_default_route_table.default[0]
module.vpc.aws_default_security_group.this[0]
module.vpc.aws_eip.nat[0]
module.vpc.aws_internet_gateway.this[0]
module.vpc.aws_nat_gateway.this[0]
module.vpc.aws_route.private_nat_gateway[0]
module.vpc.aws_route.public_internet_gateway[0]
module.vpc.aws_route_table.private[0]
module.vpc.aws_route_table.public[0]
module.vpc.aws_route_table_association.private[0]
module.vpc.aws_route_table_association.private[1]
module.vpc.aws_route_table_association.public[0]
module.vpc.aws_route_table_association.public[1]
module.vpc.aws_subnet.private[0]
module.vpc.aws_subnet.private[1]
module.vpc.aws_subnet.public[0]
module.vpc.aws_subnet.public[1]
module.vpc.aws_vpc.this[0]
```

The three `aws_default_*` entries are the network ACL, route table, and security group that AWS creates automatically with every VPC. The module takes them over so Terraform manages them too.

State files can contain secrets and resource details, so `.terraform/` and `*.tfstate*` are in `.gitignore` and were never committed.

## Drift

Drift happens when someone changes a Terraform-managed resource outside Terraform, usually in the console. The state file no longer matches reality. The next `plan` then tries to "fix" the difference, recreate something that is fine, or fail with an error like `VpcLimitExceeded`.

To diagnose it, compare `terraform state list` with what is actually in the console. To fix it, use `terraform import` to bring a resource back into state if it still exists, or `terraform state rm` to remove it from state if it is really gone.

The lesson: once a resource is managed by Terraform, every change to it should go through Terraform. The console becomes read-only for that resource.
