# Lab 06 — EC2 & Virtual Machines

## Objective

Launch a compute instance on AWS (EC2) and Azure (Linux VM), connect via SSH, install a web server, and serve a basic HTML page with student name and registration number.

---

## AWS

### Task 1 — Launch an EC2 Instance

- Instance `lab6-ec2-instance`: `t2.micro` (Free Tier), Amazon Linux 2023
- VPC + public subnet + internet gateway
- Security group: SSH (port 22) + HTTP (port 80)
- Auto-generated SSH key pair

### Task 2 — Connect via SSH

Save the private key and connect:

```bash
terraform output -raw private_key > lab6-key.pem
chmod 400 lab6-key.pem
ssh -i lab6-key.pem ec2-user@<public_ip>
```

For Windows, convert the PEM to PPK using PuTTYgen, then use PuTTY.

### Task 3 — Install Web Server

The `user_data` script automatically runs on launch:

```bash
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
```

### Task 4 — Serve Student HTML Page

A styled HTML page with student name and registration number is deployed to `/var/www/html/index.html` via `user_data`.

Open in browser: `http://<public_ip>`

### Task 5 — Terminate Instance

Always destroy resources after lab:

```
Actions → Deploy Labs → Lab 6 → aws → destroy
```

---

## Azure

### Task 1 — Launch a Linux Virtual Machine

| Resource | Description |
|----------|-------------|
| `azurerm_linux_virtual_machine` | Ubuntu 22.04 LTS, Standard_B1s (Free Tier eligible) |
| `azurerm_virtual_network` | VNet 10.0.0.0/16 |
| `azurerm_subnet` | Public subnet 10.0.1.0/24 |
| `azurerm_public_ip` | Static public IP |
| `azurerm_network_security_group` | Allow SSH (22) + HTTP (80) |

### Task 2 — Connect via SSH

```bash
terraform output -raw private_key > lab6-key.pem
chmod 400 lab6-key.pem
ssh -i lab6-key.pem azureuser@<public_ip>
```

### Tasks 3–4 — Web Server & HTML Page

The `custom_data` script installs Apache2 and deploys the same student HTML page:

```bash
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
```

Open in browser: `http://<public_ip>`

### Task 5 — Delete Resources

```
Actions → Deploy Labs → Lab 6 → azure → destroy
```

---

## Comparison

| Feature | AWS EC2 | Azure Virtual Machine |
|---------|---------|----------------------|
| Instance Type | t2.micro | Standard_B1s |
| OS | Amazon Linux 2023 | Ubuntu 22.04 LTS |
| Web Server | httpd (Apache) | Apache2 |
| Networking | VPC + Subnet + IGW | VNet + Subnet + Public IP |
| Firewall | Security Group | Network Security Group |
| SSH User | ec2-user | azureuser |
| Free Tier | 750 hrs/mo (12 months) | 750 hrs/mo (12 months) |
| Init Script | user_data | custom_data |

---

## Key Concepts

- **AMI (Amazon Machine Image)**: Template for EC2 instances containing OS and software
- **Instance Type**: Hardware configuration (CPU, RAM, storage, network)
- **Key Pair**: SSH authentication using RSA public/private keys
- **Security Group / NSG**: Virtual firewall controlling inbound/outbound traffic
- **user_data / custom_data**: Bootstrap scripts that run on first instance launch

---

## Deployment

```
Actions → Deploy Labs → Lab 6 → aws/azure → apply
```
