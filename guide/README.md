# Terraform DevOps Teaching Module

**Course**: Cloud Computing  
**Topic**: Infrastructure as Code with Terraform  
**Student**: Haseen Ullah — 22MDSWE238

---

## What is Terraform?

Terraform is an **open-source Infrastructure as Code (IaC)** tool developed by HashiCorp. It allows you to define, provision, and manage cloud infrastructure using a declarative configuration language called **HCL (HashiCorp Configuration Language)**.

Instead of manually clicking through a cloud provider's console to create servers, databases, networks, and more — you write code that describes what you want, and Terraform makes it happen.

### Why Terraform?

| Problem (Before Terraform) | Solution (With Terraform) |
|---|---|
| Manual clicking in cloud consoles | Code-driven, repeatable infrastructure |
| No record of what was created | Version-controlled `.tf` files |
| Hard to replicate environments | Same code = same environment, every time |
| Cloud vendor lock-in | Works with AWS, Azure, GCP, and 100+ providers |
| Inconsistent team setups | One shared configuration for the whole team |

---

## Module Contents

This guide is split into focused chapters. Start from the top and work your way down.

| # | File | Topic |
|---|------|-------|
| 01 | [Introduction](01-introduction.md) | What is Terraform, IaC overview, how it works |
| 02 | [Core Concepts](02-core-concepts.md) | Providers, Resources, Variables, Outputs, State, Data Sources |
| 03 | [Terraform Operations](03-terraform-operations.md) | init, plan, apply, destroy, and more |
| 04 | [Commands Cheatsheet](04-commands-cheatsheet.md) | Quick-reference card for all Terraform CLI commands |
| 05 | [Cloud Provider Setup](05-cloud-provider-setup.md) | Connecting Terraform to AWS, Azure, and GCP |
| 06 | [Code Examples](06-code-examples.md) | Hands-on examples: EC2, S3, VPC, Multi-Resource |
| 07 | [State Management](07-state-management.md) | Local vs Remote state, S3 backend, locking |
| 08 | [Modules](08-modules.md) | Reusable Terraform modules, Terraform Registry |
| 09 | [Lab Exercises](09-lab-exercises.md) | Step-by-step student labs (setup, S3, variables, full deploy) |
| 10 | [Resources & Links](10-resources-and-links.md) | Official docs, tutorials, videos, tools, community |

---

## Prerequisites

- Basic understanding of cloud computing (AWS / Azure / GCP)
- A terminal / command line environment
- An active cloud account (AWS Free Tier recommended for labs)
- Terraform installed — see [Lab 01](09-lab-exercises.md) for installation steps

---

## Quick Start

```
1. Read the Introduction          →  01-introduction.md
2. Learn Core Concepts            →  02-core-concepts.md
3. Understand the CLI workflow    →  03-terraform-operations.md
4. Set up your cloud provider     →  05-cloud-provider-setup.md
5. Try the hands-on examples      →  06-code-examples.md
6. Complete the lab exercises      →  09-lab-exercises.md
```

> ⚠️ Always run `terraform destroy` after each lab to avoid cloud billing charges.
