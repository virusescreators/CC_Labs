# Lab 07 — Networking in AWS & Azure

## Objective

Create a custom VPC/VNet named with student name and roll number, configure public and private subnets, attach an internet gateway, and associate route tables to control traffic flow.

---

## AWS

### Task 1 — Create a Custom VPC

- VPC `HaseenUllah-22MDSWE238-VPC`: CIDR `10.0.0.0/16`
- DNS support and DNS hostnames enabled

### Task 2 — Create Public and Private Subnets

| Subnet | CIDR | AZ | Public IP on Launch |
|--------|------|----|---------------------|
| `Lab7-Public-Subnet` | `10.0.1.0/24` | us-east-1a | Yes |
| `Lab7-Private-Subnet` | `10.0.2.0/24` | us-east-1b | No |

### Task 3 — Attach Internet Gateway

- Internet Gateway `Lab7-IGW` attached to the VPC
- Enables communication between the VPC and the public internet

### Task 4 — Attach Route Tables

| Route Table | Route | Target | Subnet |
|-------------|-------|--------|--------|
| `Lab7-Public-RT` | `0.0.0.0/0` | Internet Gateway | Public Subnet |
| `Lab7-Private-RT` | *(no internet route)* | — | Private Subnet |

The public route table routes all internet-bound traffic (`0.0.0.0/0`) through the Internet Gateway. The private route table has no internet route, keeping instances isolated.

### Security Groups

| Security Group | Inbound Rules | Scope |
|----------------|---------------|-------|
| `Lab7-Public-SG` | SSH (22), HTTP (80) from `0.0.0.0/0` | Public Subnet |
| `Lab7-Private-SG` | All traffic from `10.0.0.0/16` only | Private Subnet |

### Destroy Resources

```
Actions → Deploy Labs → Lab 7 → aws → destroy
```

---

## Azure

### Task 1 — Create a Custom Virtual Network

- VNet `HaseenUllah-22MDSWE238-VNet`: Address space `10.0.0.0/16`
- Azure equivalent of AWS VPC

### Task 2 — Create Public and Private Subnets

| Subnet | Address Prefix |
|--------|----------------|
| `Lab7-Public-Subnet` | `10.0.1.0/24` |
| `Lab7-Private-Subnet` | `10.0.2.0/24` |

### Task 3 — Internet Access (Route Table)

Azure VNets have implicit internet access via a system route. A public route table with an explicit `Internet` next-hop is associated with the public subnet to mirror the AWS pattern.

### Task 4 — Attach Route Tables

| Route Table | Route | Next Hop | Subnet |
|-------------|-------|----------|--------|
| `Lab7-Public-RT` | `0.0.0.0/0` | Internet | Public Subnet |
| `Lab7-Private-RT` | `0.0.0.0/0` | None (drop) | Private Subnet |

The private route table explicitly drops internet-bound traffic using `next_hop_type = "None"`.

### Network Security Groups

| NSG | Rules | Scope |
|-----|-------|-------|
| `Lab7-Public-NSG` | Allow SSH (22), HTTP (80) | Public Subnet |
| `Lab7-Private-NSG` | Allow VNet traffic, Deny Internet | Private Subnet |

### Destroy Resources

```
Actions → Deploy Labs → Lab 7 → azure → destroy
```

---

## Comparison

| Feature | AWS | Azure |
|---------|-----|-------|
| Virtual Network | VPC | VNet |
| Network Segment | Subnet | Subnet |
| Internet Access | Internet Gateway | System route / Route Table |
| Traffic Routing | Route Table | Route Table |
| Firewall | Security Group | Network Security Group (NSG) |
| IP Range Format | CIDR (e.g. 10.0.0.0/16) | Address Space (e.g. 10.0.0.0/16) |
| Private Isolation | No IGW route | next_hop_type = None |

---

## Key Concepts

- **VPC / VNet**: A logically isolated virtual network where you launch cloud resources
- **Subnet**: A range of IP addresses within the VPC/VNet used to segment the network
- **Internet Gateway**: Allows VPC resources to communicate with the public internet
- **Route Table**: A set of rules (routes) that determine where network traffic is directed
- **CIDR**: Classless Inter-Domain Routing — notation for IP address ranges (e.g. `10.0.0.0/24`)
- **Security Group / NSG**: Virtual firewall controlling inbound and outbound traffic
- **NAT Gateway**: Allows private subnet instances to reach the internet without being directly exposed
- **Elastic Load Balancing (ELB)**: Distributes incoming traffic across multiple targets for high availability

---

## Deployment

```
Actions → Deploy Labs → Lab 7 → aws/azure → apply
```
