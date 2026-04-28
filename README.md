# AWS Cloud Computing Labs

This repository contains Terraform code for 16 Cloud Computing labs, deployable via GitHub Actions

## Prerequisites

1.  **AWS Account**: An AWS Free Tier account.
2.  **AWS CloudShell**: You can run the bootstrap from the AWS Console > CloudShell.
    -   *Note: If `terraform` is not installed in CloudShell, run:*
        ```bash
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
        sudo yum -y install terraform
        ```
3.  **AWS CLI**: Configured (pre-installed in CloudShell).

## One-Time Setup (Bootstrap)

1.  Clone the repository:
    ```bash
    git clone https://github.com/mr-haseen-ullah/CC_Labs.git
    cd CC_Labs
    ```
2.  Navigate to the `bootstrap` directory:
    ```bash
    cd bootstrap
    terraform init
    terraform apply
    ```
3.  Note the outputs:
    -   `s3_bucket_name`
    -   `dynamodb_table_name`
    -   `github_deployer_access_key_id`
    -   `github_deployer_secret_access_key` (Run `terraform output -json` to see values)

## GitHub Configuration

1.  Go to your GitHub Repository > Settings > Secrets and variables > Actions.
2.  Add the following **Repository Secrets**:
    -   `AWS_ACCESS_KEY_ID`: (From bootstrap output)
    -   `AWS_SECRET_ACCESS_KEY`: (From bootstrap output)
    -   `TF_STATE_BUCKET`: (From bootstrap output)
    -   `TF_LOCK_TABLE`: (From bootstrap output)

## Deploying a Lab

1.  Go to the **Actions** tab in your repository.
2.  Select the **Deploy Labs** workflow.
3.  Click **Run workflow**.
4.  Select the **Lab Number** from the dropdown (e.g., `1`).
5.  Select **Action**: `apply` (to deploy) or `destroy` (to clean up).
6.  Click **Run workflow**.

## Labs

Each lab has its own `README.md` with full details on AWS and Azure resources. Click a lab below to learn more.

| Lab | Topic | Details |
|-----|-------|---------|
| [Lab 01](labs/lab01/) | IAM User & Billing Alarm | Create a cloud user and set up cost alerts |
| [Lab 02](labs/lab02/) | Regions, AZs & Global Services | VPC, Subnet, S3, IAM Group |
| [Lab 03](labs/lab03/) | S3, Volumes & Policies | S3 versioning, lifecycle rules, public access, EBS, EFS |
| [Lab 04](labs/lab04/) | DynamoDB & DocumentDB | Tables, items, GSI, streams, DocumentDB cluster |
| [Lab 05](labs/lab05/) | RDS & Aurora | RDS MySQL, parameter groups, snapshots, backups, read replicas |
| [Lab 06](labs/lab06/) | EC2 & Virtual Machines | Launch EC2/Azure VM, SSH access, web server setup |
| [Lab 07](labs/lab07/) | Networking | VPC, VNet, Subnets, Internet Gateways, Route Tables |
| [Lab 08](labs/lab08/) | EC2 in VPC Subnets | Launch EC2/VM in public & private subnets, bastion host access |
| [Lab 09](labs/lab09/) | Load Balancers | Deploy Application/Standard Load Balancers with target groups |
