# Lab 01 — Install Terraform & AWS CLI

## Objective

Set up your local environment for Terraform development.

---

## Part A — Install Terraform

### Linux (Ubuntu/Debian)

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform
```

### Windows

Download installer from: https://developer.hashicorp.com/terraform/install

### Verify

```bash
terraform version
```

---

## Part B — Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

---

## Part C — Configure AWS Credentials

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

---

## Deliverable

Screenshot showing `terraform version` and `aws sts get-caller-identity` output.
