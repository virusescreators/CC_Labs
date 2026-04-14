# 03 — Terraform Operations

## The Core Workflow

```
terraform init → terraform plan → terraform apply → terraform destroy
```

Every Terraform project follows this lifecycle.

---

## terraform init

**Purpose**: Initializes the working directory. Downloads provider plugins and sets up the backend.

```bash
terraform init
```

Run this:
- The very first time you work in a directory
- After adding a new provider
- After changing backend configuration

---

## terraform validate

**Purpose**: Checks your `.tf` files for syntax errors without connecting to any cloud.

```bash
terraform validate
```

---

## terraform fmt

**Purpose**: Automatically formats your code to follow Terraform style conventions.

```bash
terraform fmt
```

---

## terraform plan

**Purpose**: Shows you a preview of what Terraform will create, change, or destroy — without doing anything yet.

```bash
terraform plan
```

Output symbols:
- `+` — will be **created**
- `-` — will be **destroyed**
- `~` — will be **updated in place**
- `-/+` — will be **destroyed and recreated**

Save a plan to a file:
```bash
terraform plan -out=myplan.tfplan
```

---

## terraform apply

**Purpose**: Executes the plan and creates/updates/destroys infrastructure on the cloud.

```bash
terraform apply
```

Apply a saved plan (no prompt):
```bash
terraform apply myplan.tfplan
```

Auto-approve (skip yes/no prompt):
```bash
terraform apply -auto-approve
```

---

## terraform destroy

**Purpose**: Destroys ALL infrastructure managed by the current Terraform configuration.

```bash
terraform destroy
```

Destroy a specific resource:
```bash
terraform destroy -target=aws_instance.my_server
```

> ⚠️ This deletes real infrastructure. Always double-check before confirming.

---

## terraform show

**Purpose**: Displays the current state or a saved plan in a human-readable format.

```bash
terraform show
terraform show myplan.tfplan
```

---

## terraform state

**Purpose**: Inspect and manipulate the state file.

```bash
terraform state list                         # List all resources in state
terraform state show aws_instance.server     # Show details of one resource
terraform state rm aws_instance.server       # Remove resource from state (without destroying it)
```

---

## terraform output

**Purpose**: Print output values from the state.

```bash
terraform output
terraform output server_ip
```

---

## terraform import

**Purpose**: Import existing cloud resources into Terraform state (so Terraform can manage them).

```bash
terraform import aws_instance.server i-1234567890abcdef0
```

---

> See also: [Commands Cheatsheet →](04-commands-cheatsheet.md)
