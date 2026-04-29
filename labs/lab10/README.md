# Lab 10: Auto Scaling Group with Application Load Balancer

An **Auto Scaling Group (ASG)** in AWS is a service that automatically manages a group of **EC2 instances**, helping you maintain **availability**, **performance**, and **cost-efficiency.**

### Core Functions of an Auto Scaling Group:

1. **Automatic Scaling**
   - **Scale Out**: Launch more EC2 instances when demand increases (e.g., high CPU, traffic).
   - **Scale In**: Terminate instances when demand drops (to save cost).

2. **Health Monitoring & Replacement**
   - If an EC2 instance becomes **unhealthy**, ASG can **automatically replace** it.

3. **Availability Management**
   - Ensures a **minimum number** of instances are always running across **multiple Availability Zones**.

### Example Use Case:

Imagine you run a website with traffic spikes at noon:
- ASG scales from 2 → 10 EC2s automatically when CPU goes high.
- At night, when traffic drops, it scales back to 2 to save cost.
- If any EC2 crashes, it replaces it immediately.

---

## LAB TASK:

**Create your Auto Scaling Group (ASG) instances to be accessible only from your Load Balancer within your VPC subnets.**

---

## Solution & Code Explanation

This lab involves implementing the infrastructure in both AWS and Azure using Terraform. 

### 1. AWS Implementation (`aws/main.tf`)

In AWS, we implement the task using an Auto Scaling Group behind an Application Load Balancer (ALB).

* **Networking**: We create a Custom VPC and two Public Subnets in different Availability Zones (`us-east-1a` and `us-east-1b`). ALBs require at least two subnets in different AZs.
* **Security Groups**: 
  * `lab10_alb_sg`: Attached to the ALB. It allows HTTP (port 80) traffic from anywhere (`0.0.0.0/0`).
  * `lab10_asg_sg`: Attached to the EC2 instances. **Crucially, it only allows inbound HTTP traffic from the ALB's Security Group**. This satisfies the lab task requirement ensuring the instances are only accessible via the Load Balancer.
* **Compute (Launch Template & ASG)**: 
  * A **Launch Template** is defined to bootstrap `t2.micro` Amazon Linux instances. It uses `user_data` to install Apache and echo the Availability Zone the instance is running in.
  * An **Auto Scaling Group** is created using this template, spanning both subnets. It's configured to maintain a `desired_capacity` of 2 instances, scaling between a minimum of 1 and a maximum of 3.
* **Load Balancing**: The ALB listens on port 80 and forwards traffic to a **Target Group**. The ASG is registered with this Target Group, ensuring traffic is dynamically routed to the ASG instances as they scale in or out.

### 2. Azure Implementation (`azure/main.tf`)

In Azure, the equivalent of an Auto Scaling Group is a **Virtual Machine Scale Set (VMSS)**. We place this behind a Standard Load Balancer.

* **Networking**: We create a Virtual Network (VNet) and a single Subnet.
* **Network Security Group (NSG)**: We attach an NSG to the subnet allowing HTTP traffic and Load Balancer health probes.
* **Load Balancing**: 
  * We provision a Standard Public IP and a **Standard Load Balancer**.
  * We create a **Backend Address Pool** and define a Load Balancing Rule that directs traffic from port 80 on the frontend IP to port 80 on the backend pool.
  * We define a Health Probe to check the instances on port 80.
* **Compute (Virtual Machine Scale Set)**:
  * We deploy a `azurerm_linux_virtual_machine_scale_set` with a capacity of 2 instances running Ubuntu.
  * We use a `custom_data` script to automatically install and start Apache when the instances boot.
  * We attach the primary Network Interface of the VMSS to the Load Balancer's backend address pool. This allows the Load Balancer to automatically distribute traffic to the instances in the scale set.
