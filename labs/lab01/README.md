# Lab 01 — IAM User & Billing Alarm

## Objective

Create a cloud user account and set up a billing alarm to monitor costs.

---

## AWS

**Resources created:**

| Resource | Description |
|----------|-------------|
| `aws_iam_user` | IAM user `student-user` for programmatic and console access |
| `aws_iam_access_key` | Access key pair for the student user |
| `aws_iam_user_login_profile` | Console login profile (requires PGP key) |
| `aws_cloudwatch_metric_alarm` | Billing alarm that triggers when estimated charges exceed $0.01 |

**Key outputs:**
- `student_user_name` — Name of the created IAM user
- `student_user_access_key_id` — Access key ID
- `student_user_secret_access_key` — Secret access key (sensitive)

---

## Azure

**Resources created:**

| Resource | Description |
|----------|-------------|
| `azuread_user` | Azure AD user `student-user@<domain>` with display name "Student User" |

**Key outputs:**
- `student_azure_ad_user_upn` — User principal name
- `student_azure_ad_user_initial_password` — Initial password (sensitive)

> **Note:** Azure requires passing the `azure_domain` input when deploying via GitHub Actions (e.g., `contoso.onmicrosoft.com`).

---

## Deployment

```
Actions → Deploy Labs → Lab 1 → aws/azure → apply
```
