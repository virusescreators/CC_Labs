# Lab 11: Application Load Balancer (Path-Based Routing)

**Path-based routing** (also called **URL routing**) allows your **Application Load Balancer (ALB)** to **route incoming requests to different target groups based on the request path** (the part of the URL after the domain).

Path-based routing is **essential** in microservices architecture, multi-app hosting, or anything needing scalability and clean architecture under a single domain. It simplifies complexity, enhances scalability, improves cost-efficiency, and allows separation of concerns.

### Why Path-Based Routing?

Consider a company website:
- `https://company.com/app` → Frontend React app
- `https://company.com/api` → Node.js backend
- `https://company.com/admin` → Internal admin panel

**Without** path-based routing:
- You'd need 3 load balancers or 3 subdomains.
- You'd need to manage SSL certificates for each.
- It would cost more and add operational overhead.

**With path-based routing:**
- You use **one ALB**.
- Set routing rules:
  - `/app/*` → Target Group A (frontend)
  - `/api/*` → Target Group B (backend)

---

## LAB TASK:

1. Implement path-based routing using an ALB with **two Auto Scaling Groups**.
2. Route `/app/*` traffic to a **Frontend ASG** and `/api/*` traffic to a **Backend API ASG**.
3. Serve a distinct static HTML page from each ASG so you can differentiate the two groups.
4. Remember to **terminate your instances** once done.

---

## Solution & Code Explanation

This lab extends Lab 10 by adding path-based routing rules on top of the ASG + ALB architecture. Both AWS and Azure implementations are provided using Terraform.

### 1. AWS Implementation (`aws/main.tf`)

In AWS, we use an **Application Load Balancer (ALB)** with listener rules to implement path-based routing across two Auto Scaling Groups.

* **Networking**: A Custom VPC with two Public Subnets in different Availability Zones (`us-east-1a` and `us-east-1b`), required for ALB multi-AZ deployment.
* **Security Groups**:
  * `lab11_alb_sg`: Attached to the ALB. Allows HTTP (port 80) from anywhere (`0.0.0.0/0`).
  * `lab11_asg_sg`: Attached to EC2 instances. **Only allows inbound HTTP from the ALB's Security Group** — instances are unreachable directly from the internet.
* **Two Target Groups**:
  * `lab11_tg_app`: Health-checks on `/app/` — receives traffic routed via the `/app/*` rule.
  * `lab11_tg_api`: Health-checks on `/api/` — receives traffic routed via the `/api/*` rule.
* **ALB Listener & Path Rules**:
  * The listener's **default action** returns a `404 fixed-response` for any unmatched path.
  * **Rule priority 10**: Matches `/app/*` → forwards to `lab11_tg_app`.
  * **Rule priority 20**: Matches `/api/*` → forwards to `lab11_tg_api`.
* **Two Launch Templates & Two ASGs**:
  * **App ASG**: EC2s install Apache and serve a styled HTML page at `/app/index.html` displaying the Availability Zone.
  * **API ASG**: EC2s install Apache and serve a styled HTML page at `/api/index.html` displaying the Availability Zone.
  * Both ASGs run `desired_capacity = 2` instances across both subnets (min: 1, max: 3).

### 2. Azure Implementation (`azure/main.tf`)

In Azure, **Application Gateway** (not Azure Load Balancer) is the equivalent of AWS ALB — it natively supports HTTP path-based routing (URL path maps) and WAF.

* **Networking**: A VNet with two subnets — one for the VMSS instances (`10.0.1.0/24`) and a dedicated subnet for the Application Gateway (`10.0.2.0/24`), which is a requirement for Azure Application Gateway.
* **NSG**: Allows HTTP (port 80) from the Internet and from `AzureLoadBalancer` for health probes.
* **Application Gateway (Standard_v2)**:
  * A **URL Path Map** defines two path rules:
    * `/app/*` → App Backend Pool (serves the frontend VMSS)
    * `/api/*` → API Backend Pool (serves the backend VMSS)
  * The routing rule type is `PathBasedRouting`, pointing to the URL path map.
* **Two VMSS Deployments**:
  * **App VMSS**: Ubuntu instances that serve a styled HTML page at `/app/index.html`.
  * **API VMSS**: Ubuntu instances that serve a styled HTML page at `/api/index.html`.
  * Each VMSS NIC's `ip_configuration` is linked to its respective Application Gateway backend pool.
