# Introduction — Extended Notes

## IaC Approaches: Declarative vs Imperative

| Approach | Description | Example Tools |
|----------|-------------|---------------|
| **Declarative** | You describe the *desired end state*. The tool figures out how to get there. | Terraform, CloudFormation |
| **Imperative** | You describe the *exact steps* to reach the goal. | Ansible, Bash scripts |

Terraform uses the **declarative** approach. You say *"I want 3 EC2 instances"* — Terraform determines if it needs to create, update, or do nothing.

## Terraform vs Configuration Management

- **Terraform** → provisions infrastructure (servers, networks, databases)
- **Ansible / Chef / Puppet** → configures software on existing infrastructure

They are complementary: Terraform creates the server, Ansible installs software on it.

## HCL — HashiCorp Configuration Language

HCL is Terraform's native language. Key features:
- Human-readable (unlike JSON)
- Supports comments (`#` and `//`)
- Strongly typed variables
- Built-in functions (`join`, `lookup`, `length`, etc.)

```hcl
# Example: A simple resource block
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "HelloWorld"
  }
}
```

## Terraform Editions

| Edition | Use Case | Cost |
|---------|----------|------|
| **Terraform CLI** (Open Source) | Individual / small team use | Free |
| **Terraform Cloud** | Team collaboration, remote state | Free tier + paid |
| **Terraform Enterprise** | Large enterprises, self-hosted | Paid |

For this course, we use **Terraform CLI** (open source).

---

> Back to: [README](README.md)
