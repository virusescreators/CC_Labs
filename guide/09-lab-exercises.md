# 09 — Lab Exercises

Complete these labs in order. Each builds on the previous.

| Lab | Topic | Estimated Time |
|---|---|---|
| [Lab 01](#lab-01--install-terraform--aws-cli) | Install Terraform & AWS CLI | 20 min |
| [Lab 02](#lab-02--create-your-first-terraform-resource) | Create your first resource (S3 bucket) | 30 min |
| [Lab 03](#lab-03--variables-and-outputs) | Use variables and outputs | 30 min |
| [Lab 04](#lab-04--full-cloud-deployment) | Full cloud deployment (EC2 + VPC) | 45 min |

> ⚠️ Always run `terraform destroy` at the end of each lab to avoid cloud charges.

---

## Lab 01 — Install Terraform & AWS CLI

### Objective

Set up your local environment for Terraform development.

### Part A — Install Terraform

**Linux (Ubuntu/Debian)**
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform
```

**Windows**

Download installer from: https://developer.hashicorp.com/terraform/install

**Verify**
```bash
terraform version
```

### Part B — Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### Part C — Configure AWS Credentials

1. Log into the AWS Console
2. Go to IAM → Users → Your User → Security Credentials
3. Create an Access Key
4. Run:
```bash
aws configure
# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region name: us-east-1
# Default output format: json
```
5. Test:
```bash
aws sts get-caller-identity
```

### Deliverable

Screenshot showing `terraform version` and `aws sts get-caller-identity` output.

---

## Lab 02 — Create Your First Terraform Resource

### Objective

Use Terraform to create an S3 bucket on AWS.

### Steps

1. Create a new directory:
```bash
mkdir my-first-terraform
cd my-first-terraform
```

2. Create `main.tf`:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "student-bucket-<your-name>-2024"   # Must be globally unique

  tags = {
    Name = "my-first-terraform-bucket"
  }
}
```

3. Run:
```bash
terraform init
terraform plan
terraform apply
```

4. Verify in AWS Console → S3

5. Clean up:
```bash
terraform destroy
```

### Deliverable

Screenshot of `terraform apply` output and the bucket visible in the AWS Console.

---

## Lab 03 — Variables and Outputs

### Objective

Refactor Lab 02 to use variables and outputs.

### Steps

1. Split your code into separate files:

**variables.tf**
```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "region" {
  default = "us-east-1"
}
```

**outputs.tf**
```hcl
output "bucket_arn" {
  value = aws_s3_bucket.my_bucket.arn
}
```

**terraform.tfvars**
```hcl
bucket_name = "student-bucket-yourname-2024"
```

2. Run:
```bash
terraform apply
terraform output
```

### Deliverable

Show the `terraform output` result with the bucket ARN displayed.

---

## Lab 04 — Full Cloud Deployment

### Objective

Deploy the multi-resource example from [Example 4](06-code-examples.md#example-4--multi-resource-deployment-ec2--security-group--vpc).

### Steps

1. Navigate to or create the example directory

2. Run:
```bash
terraform init
terraform plan
terraform apply
```

3. After apply, copy the `web_server_public_ip` from the output.

4. Open a browser and visit: `http://<public_ip>`
   - You should see the nginx welcome page.

5. Explore the state:
```bash
terraform state list
terraform state show aws_instance.web
```

6. Clean up:
```bash
terraform destroy
```

### Deliverable

Screenshot of:
- `terraform apply` completion
- nginx welcome page in browser
- `terraform state list` output

---

> Next: [Resources & Links →](10-resources-and-links.md)
