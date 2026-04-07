# Lab 7: Networking in AWS and Azure

This directory contains the Terraform code required to automate the setup of cloud networking components on both AWS and Azure.  

## Lab Tasks
The objective of this lab is to establish isolated cloud networks, create public and private subnets, configure gateways for internet access, and manage network traffic using route tables.

Specifically:
1. Create a custom VPC (`AWS`) and Virtual Network (`Azure`).
2. Create `public` and `private` subnets within these isolated networks.
3. Attach an Internet Gateway to the VPC (AWS only).
4. Create and attach route tables for public internet access vs internal/local access.

## Directory Structure
- `/aws`: `main.tf` to spin up VPC, subnets, IGW, and Route Tables.
- `/azure`: `main.tf` to spin up VNet, subnets, and Route Tables.

## How to Deploy

### AWS
1. Navigate to the AWS folder: `cd aws`
2. Initialize Terraform: `terraform init`
3. Preview changes: `terraform plan`
4. Apply the configuration: `terraform apply -auto-approve`

### Azure
1. Navigate to the Azure folder: `cd azure`
2. Initialize Terraform: `terraform init`
3. Preview changes: `terraform plan`
4. Apply the configuration: `terraform apply -auto-approve`

**Note**: To clean up resources and prevent unwanted charges, run `terraform destroy -auto-approve` from the respective directories once testing is complete.
