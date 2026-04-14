# Terraform DevOps Module

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

## Module Outline

| Folder | Topic |
|---|---|
| [`01-introduction/`](01-introduction/) | What is Terraform, IaC overview |
| [`02-core-concepts/`](02-core-concepts/) | Providers, Resources, Variables, State |
| [`03-terraform-operations/`](03-terraform-operations/) | init, plan, apply, destroy and more |
| [`04-connecting-to-cloud/`](04-connecting-to-cloud/) | AWS, Azure, GCP provider setup |
| [`05-examples/`](05-examples/) | Hands-on Terraform code examples |
| [`06-state-management/`](06-state-management/) | How Terraform tracks infrastructure |
| [`07-modules/`](07-modules/) | Reusable Terraform modules |
| [`08-lab-exercises/`](08-lab-exercises/) | Step-by-step student labs |
| [`resources.md`](resources.md) | Official docs, tutorials, tools |

---

## Prerequisites

- Basic understanding of cloud computing (AWS/Azure/GCP)
- A terminal / command line environment
- An active cloud account (AWS Free Tier recommended for labs)
- Terraform installed — see [Lab 01](08-lab-exercises/lab-01-setup.md) for installation steps

---

> Start with [`01-introduction/README.md`](01-introduction/)
