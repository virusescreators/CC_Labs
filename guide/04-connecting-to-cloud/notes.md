# Connecting to Cloud — Extended Notes

## AWS Authentication

### Step 1 — Install AWS CLI

```bash
# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify
aws --version
```

### Step 2 — Configure Credentials

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format
```

Or set environment variables:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Credential Priority Order

1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
2. `~/.aws/credentials` file (from `aws configure`)
3. IAM Instance Profile (when running on EC2)

---

## Azure Authentication

### Step 1 — Install Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
```

### Step 2 — Service Principal (for CI/CD)

```bash
az ad sp create-for-rbac --name "terraform-deployer" --role Contributor
# Outputs: appId, password, tenant
```

Set environment variables:
```bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_TENANT_ID="<tenant>"
export ARM_SUBSCRIPTION_ID="<subscriptionId>"
```

---

## GCP Authentication

### Step 1 — Install gcloud CLI

```bash
curl https://sdk.cloud.google.com | bash
gcloud init
gcloud auth application-default login
```

### Step 2 — Service Account (for CI/CD)

```bash
gcloud iam service-accounts create terraform-deployer
gcloud iam service-accounts keys create key.json --iam-account=terraform-deployer@PROJECT.iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS="key.json"
```

---

> ⚠️ **Security Rule**: Never hardcode credentials in `.tf` files. Use environment variables or a secrets manager.

> Back to: [README](README.md)
