# AWS Cloud Computing Labs

This repository contains Terraform code for 16 Cloud Computing labs, deployable via GitHub Actions.

## Prerequisites

1.  **AWS Account**: An AWS Free Tier account.
2.  **Terraform**: Installed locally for bootstrapping.
3.  **AWS CLI**: Configured with your root or admin credentials.

## One-Time Setup (Bootstrap)

1.  Navigate to the `bootstrap` directory:
    ```bash
    cd bootstrap
    terraform init
    terraform apply
    ```
2.  Note the outputs:
    -   `s3_bucket_name`
    -   `dynamodb_table_name`
    -   `github_deployer_access_key_id`
    -   `github_deployer_secret_access_key`

## GitHub Configuration

1.  Go to your GitHub Repository > Settings > Secrets and variables > Actions.
2.  Add the following **Repository Secrets**:
    -   `AWS_ACCESS_KEY_ID`: (From bootstrap output)
    -   `AWS_SECRET_ACCESS_KEY`: (From bootstrap output)
    -   `TF_STATE_BUCKET`: (From bootstrap output, e.g., `cc-labs-terraform-state-xxxx`)
    -   `TF_LOCK_TABLE`: (From bootstrap output, e.g., `cc-labs-terraform-lock`)

## Deploying a Lab

1.  Go to the **Actions** tab in your repository.
2.  Select the **Deploy Labs** workflow.
3.  Click **Run workflow**.
4.  Select the **Lab Number** from the dropdown (e.g., `1`).
5.  Select **Action**: `apply` (to deploy) or `destroy` (to clean up).
6.  Click **Run workflow**.

## Lab Details

### Lab 1
- Creates an IAM User `student-user`.
- Sets up a Billing Alarm for > $0.01.
