# Example 04 — Multi-Resource Deployment (EC2 + Security Group + VPC)

**Goal**: Deploy a full stack — VPC, subnet, security group, and an EC2 instance — together in one configuration.

## What this creates

- 1 VPC
- 1 Public subnet
- 1 Internet Gateway + Route Table
- 1 Security Group (allows SSH on port 22 and HTTP on port 80)
- 1 EC2 instance inside the VPC

## How to run

```bash
cd example-04-multi-resource
terraform init
terraform plan
terraform apply

# After apply, visit: http://<web_server_public_ip>
# You should see the nginx welcome page

terraform destroy   # IMPORTANT — avoid charges!
```
