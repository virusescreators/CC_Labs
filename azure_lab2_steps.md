# Lab 2: Azure Portal Instructions (Optional)

This guide outlines how to replicate the infrastructure concepts from AWS Lab 2 (Regions, Availability Zones, and Global vs. Regional resources) using the Microsoft Azure Portal.

## Equivalents

| AWS Resource | Azure Resource | Scope |
| :--- | :--- | :--- |
| **Region** | **Region** | Regional |
| **Availability Zone** | **Availability Zone** | Zonal |
| **VPC** | **Virtual Network (VNet)** | Regional |
| **Subnet** | **Subnet** | Regional (Resource placement can be Zonal) |
| **S3 Bucket** | **Storage Account (Container)** | Regional (Data location) |
| **IAM Group** | **Entra ID Group** | Global |

---

## Step 1: Create a Resource Group
*A container that holds related resources for an Azure solution.*

1.  Log in to the **Azure Portal**.
2.  Search for **Resource groups** in the top search bar.
3.  Click **+ Create**.
4.  **Subscription**: Select your subscription (e.g., Azure for Students).
5.  **Resource group name**: Enter `Lab2-RG`.
6.  **Region**: Select a region close to you (e.g., `(US) East US`).
7.  Click **Review + create** > **Create**.

---

## Step 2: Create a Virtual Network (Regional Resource)
*Demonstrates a resource bound to a specific region.*

1.  Search for **Virtual networks**.
2.  Click **+ Create**.
3.  **Resource Group**: Select `Lab2-RG`.
4.  **Name**: Enter `Lab2-VNet`.
5.  **Region**: Ensure it matches your Resource Group (e.g., `East US`).
6.  Click **Next: IP Addresses**.
    -   Notice the default IPv4 address space (e.g., `10.0.0.0/16`).
7.  Click **Review + create** > **Create**.

---

## Step 3: Explore Availability Zones (Conceptual)
*Unlike AWS where you explicitly create a subnet in an AZ, Azure subnets are regional. You typically select the AZ when deploying a Virtual Machine.*

1.  Search for **Virtual machines**.
2.  Click **+ Create** > **Azure virtual machine**.
3.  **Resource Group**: `Lab2-RG`.
4.  **Virtual machine name**: `Lab2-VM` (We won't actually create it, just explore).
5.  **Region**: `East US`.
6.  **Availability options**: Select **Availability zone**.
7.  **Availability zone**: Select `Zone 1`, `Zone 2`, or `Zone 3`.
    -   *Observe: This is where you physically place your compute resource in an isolated datacenter within the region.*
8.  **Cancel** the creation (unless you want to spend credits).

---

## Step 4: Create a Storage Account (Regional/Global Name)
*Demonstrates a service with a globally unique name but regional data storage.*

1.  Search for **Storage accounts**.
2.  Click **+ Create**.
3.  **Resource Group**: `Lab2-RG`.
4.  **Storage account name**: Enter a unique name (e.g., `lab2storage<yourname>`). *Must be globally unique across all of Azure.*
5.  **Region**: `East US` (The data lives here).
6.  **Redundancy**: Select **LRS (Locally-redundant storage)** to keep it cheaper/simpler.
7.  Click **Review** > **Create**.

---

## Step 5: Create a User/Group in Entra ID (Global Resource)
*Demonstrates a global identity service independent of regions.*

1.  Search for **Microsoft Entra ID** (formerly Azure Active Directory).
2.  In the left sidebar, click **Groups**.
3.  Click **New group**.
4.  **Group type**: `Security`.
5.  **Group name**: `Lab2-Global-Group`.
6.  **Membership type**: `Assigned`.
7.  Click **Create**.
    -   *Observe: You did not select a region. This identity exists globally for your tenant.*
