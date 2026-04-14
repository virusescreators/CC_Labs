# Lab 08 — Launching EC2 Instances in VPC Subnets

## Objective

Launch EC2 instances (AWS) / Virtual Machines (Azure) in public and private subnets. The private instance must only be accessible from the public subnet — demonstrating bastion host / jump-box networking.

---

## AWS

### Task 1 — Create VPC with Public & Private Subnets

- VPC `HaseenUllah-22MDSWE238-Lab8-VPC`: CIDR `10.0.0.0/16`
- DNS support and DNS hostnames enabled
- Internet Gateway `Lab8-IGW` attached to the VPC

| Subnet | CIDR | AZ | Public IP on Launch |
|--------|------|----|---------------------|
| `Lab8-Public-Subnet` | `10.0.1.0/24` | us-east-1a | Yes |
| `Lab8-Private-Subnet` | `10.0.2.0/24` | us-east-1b | No |

| Route Table | Route | Target | Subnet |
|-------------|-------|--------|--------|
| `Lab8-Public-RT` | `0.0.0.0/0` | Internet Gateway | Public Subnet |
| `Lab8-Private-RT` | *(no internet route)* | — | Private Subnet |

### Task 2 — Launch Public EC2 Instance

- Instance Type: `t2.micro` (Free Tier eligible)
- AMI: Amazon Linux 2023
- Subnet: Public (`10.0.1.0/24`)
- Public IP: **Yes**
- Acts as a **bastion / jump host** to reach the private instance
- Runs a web server (httpd) with a student info page

### Task 3 — Launch Private EC2 Instance

- Instance Type: `t2.micro` (Free Tier eligible)
- AMI: Amazon Linux 2023
- Subnet: Private (`10.0.2.0/24`)
- Public IP: **No**
- Accessible **only** from the public subnet via SSH/ping

### Security Groups

| Security Group | Inbound Rules | Scope |
|----------------|---------------|-------|
| `Lab8-Public-SG` | SSH (22), HTTP (80), ICMP from `0.0.0.0/0` | Public Subnet |
| `Lab8-Private-SG` | SSH (22), ICMP from `10.0.1.0/24` only; all traffic from `10.0.0.0/16` | Private Subnet |

### Task 4 — SSH into Public EC2 & Ping Private EC2

```bash
# Save the SSH key
terraform output -raw private_key > lab8-key.pem
chmod 400 lab8-key.pem

# SSH into the public instance
ssh -i lab8-key.pem ec2-user@<public_ec2_public_ip>

# From the public instance, ping the private instance
ping <private_ec2_private_ip>
```

### Task 5 — Verify Private Isolation

- Ping from **public EC2 → private EC2**: ✅ Succeeds (allowed by SG)
- Ping from **outside VPC → private EC2**: ❌ Fails (no public IP, no internet route)

### Destroy Resources

```
Actions → Deploy Labs → Lab 8 → aws → destroy
```

---

## Azure

### Task 1 — Create VNet with Public & Private Subnets

- VNet `HaseenUllah-22MDSWE238-Lab8-VNet`: Address space `10.0.0.0/16`

| Subnet | Address Prefix |
|--------|----------------|
| `Lab8-Public-Subnet` | `10.0.1.0/24` |
| `Lab8-Private-Subnet` | `10.0.2.0/24` |

| Route Table | Route | Next Hop | Subnet |
|-------------|-------|----------|--------|
| `Lab8-Public-RT` | `0.0.0.0/0` | Internet | Public Subnet |
| `Lab8-Private-RT` | `0.0.0.0/0` | None (drop) | Private Subnet |

### Task 2 — Launch Public VM (Bastion Host)

- Size: `Standard_B1s` (Free Tier eligible)
- OS: Ubuntu 22.04 LTS
- Subnet: Public (`10.0.1.0/24`)
- Public IP: **Yes** (Static)
- Runs Apache2 web server with a student info page

### Task 3 — Launch Private VM

- Size: `Standard_B1s`
- OS: Ubuntu 22.04 LTS
- Subnet: Private (`10.0.2.0/24`)
- Public IP: **No**
- Accessible **only** from the public subnet via SSH/ping

### Network Security Groups

| NSG | Rules | Scope |
|-----|-------|-------|
| `Lab8-Public-NSG` | Allow SSH (22), HTTP (80), ICMP | Public Subnet |
| `Lab8-Private-NSG` | Allow SSH, ICMP from `10.0.1.0/24`; Allow VNet; Deny Internet | Private Subnet |

### Task 4 — SSH into Public VM & Ping Private VM

```bash
# Save the SSH key
terraform output -raw private_key > lab8-key.pem
chmod 400 lab8-key.pem

# SSH into the public VM
ssh -i lab8-key.pem azureuser@<public_vm_public_ip>

# From the public VM, ping the private VM
ping <private_vm_private_ip>
```

### Task 5 — Verify Private Isolation

- Ping from **public VM → private VM**: ✅ Succeeds (allowed by NSG)
- Ping from **outside VNet → private VM**: ❌ Fails (no public IP, internet denied)

### Destroy Resources

```
Actions → Deploy Labs → Lab 8 → azure → destroy
```

---

## Comparison

| Feature | AWS | Azure |
|---------|-----|-------|
| Virtual Network | VPC | VNet |
| Public Instance | EC2 (t2.micro) | Linux VM (Standard_B1s) |
| Private Instance | EC2 (t2.micro) | Linux VM (Standard_B1s) |
| Firewall | Security Group | Network Security Group (NSG) |
| Private Access Control | SG ingress from public CIDR | NSG rule from public CIDR |
| Bastion Concept | Public EC2 → SSH to Private EC2 | Public VM → SSH to Private VM |
| Internet Isolation | No IGW route in private RT | next_hop_type = None |

---

## Key Concepts

- **Bastion Host**: A hardened public instance used as the sole entry point to access private instances
- **Jump Box**: Another name for a bastion host — you "jump" through it to reach private resources
- **Public Subnet**: A subnet with a route to the Internet Gateway; instances can have public IPs
- **Private Subnet**: A subnet with no internet route; instances have no public IPs and are isolated
- **Security Group / NSG**: Virtual firewall that restricts inbound/outbound traffic by CIDR, port, and protocol
- **ICMP**: Internet Control Message Protocol — used by `ping` to test network connectivity
- **SSH Tunneling**: Technique to securely access private instances through a bastion host

---

## Deployment

```
Actions → Deploy Labs → Lab 8 → aws/azure → apply
```
