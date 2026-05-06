# Lab 11 – Azure CLI Implementation Guide
## ALB Path-Based Routing (Application Gateway + 2 VMSS)

> Run all commands in **Azure Cloud Shell** (bash) or a local terminal with `az` CLI installed and logged in.

---

## STEP 0 — Login & Set Variables

```bash
# Login to Azure (skip if already logged in via Cloud Shell)
az login

# ── Set all reusable variables (edit LOCATION if needed) ──────────────────────
RG="Lab11-RG"
LOCATION="eastus"
VNET="Lab11-VNet"
VMSS_SUBNET="Lab11-Subnet"
AGW_SUBNET="Lab11-AGW-Subnet"
NSG="Lab11-NSG"
AGW_PIP="Lab11-AGW-PIP"
AGW="Lab11-AGW"
VMSS_APP="lab11-vmss-app"
VMSS_API="lab11-vmss-api"
ADMIN_USER="azureuser"
ADMIN_PASS="Lab11P@ssw0rd!"   # Change this to something secure
```

---

## STEP 1 — Create Resource Group

```bash
az group create \
  --name $RG \
  --location $LOCATION
```

---

## STEP 2 — Create Virtual Network & Subnets

```bash
# Create VNet
az network vnet create \
  --resource-group $RG \
  --name $VNET \
  --address-prefix 10.0.0.0/16 \
  --tags Name="HaseenUllah-22MDSWE238-Lab11-VNet"

# Subnet for VMSS instances (10.0.1.0/24)
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET \
  --name $VMSS_SUBNET \
  --address-prefix 10.0.1.0/24

# Dedicated subnet for Application Gateway (10.0.2.0/24)
# NOTE: App Gateway REQUIRES its own dedicated subnet
az network vnet subnet create \
  --resource-group $RG \
  --vnet-name $VNET \
  --name $AGW_SUBNET \
  --address-prefix 10.0.2.0/24
```

---

## STEP 3 — Create & Attach NSG

```bash
# Create the NSG
az network nsg create \
  --resource-group $RG \
  --name $NSG

# Rule 1: Allow HTTP from Internet
az network nsg rule create \
  --resource-group $RG \
  --nsg-name $NSG \
  --name AllowHTTP \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 80

# Rule 2: Allow App Gateway / Load Balancer health probes
az network nsg rule create \
  --resource-group $RG \
  --nsg-name $NSG \
  --name AllowLBHealthProbe \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix AzureLoadBalancer \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 80

# Attach NSG to the VMSS subnet
az network vnet subnet update \
  --resource-group $RG \
  --vnet-name $VNET \
  --name $VMSS_SUBNET \
  --network-security-group $NSG
```

---

## STEP 4 — Create Public IP for Application Gateway

```bash
az network public-ip create \
  --resource-group $RG \
  --name $AGW_PIP \
  --sku Standard \
  --allocation-method Static
```

---

## STEP 5 — Create Application Gateway (with Path-Based Routing)

This is the core step. We create the Application Gateway with:
- Two backend pools (App and API)
- Two HTTP settings
- A URL path map with two path rules
- A `PathBasedRouting` request routing rule

```bash
# Get subnet resource ID for App Gateway
AGW_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG \
  --vnet-name $VNET \
  --name $AGW_SUBNET \
  --query id -o tsv)

az network application-gateway create \
  --resource-group $RG \
  --name $AGW \
  --location $LOCATION \
  --sku Standard_v2 \
  --capacity 2 \
  --public-ip-address $AGW_PIP \
  --subnet $AGW_SUBNET_ID \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --routing-rule-type Basic \
  --priority 10
```

> ⏳ This takes **5–10 minutes** to provision.
>
> **Note:** We use `--routing-rule-type Basic` here intentionally. Azure requires a URL Path Map
> to already exist before a `PathBasedRouting` rule can reference it — but the path map can only
> be created *after* the gateway exists. We update the rule to `PathBasedRouting` in Step 9.

---

## STEP 6 — Configure Backend Pools

By default the gateway creates one backend pool. We rename it and add a second.

```bash
# Rename default backend pool → App pool
az network application-gateway address-pool update \
  --resource-group $RG \
  --gateway-name $AGW \
  --name appGatewayBackendPool \
  --new-name appGwAppBackendPool

# Create second backend pool for API
az network application-gateway address-pool create \
  --resource-group $RG \
  --gateway-name $AGW \
  --name appGwApiBackendPool
```

---

## STEP 7 — Configure HTTP Settings

```bash
# Update default HTTP settings → used for App pool
az network application-gateway http-settings update \
  --resource-group $RG \
  --gateway-name $AGW \
  --name appGatewayBackendHttpSettings \
  --new-name appGwAppHttpSettings \
  --port 80 \
  --protocol Http \
  --timeout 30

# Create HTTP settings for API pool
az network application-gateway http-settings create \
  --resource-group $RG \
  --gateway-name $AGW \
  --name appGwApiHttpSettings \
  --port 80 \
  --protocol Http \
  --timeout 30
```

---

## STEP 8 — Configure URL Path Map (Path-Based Routing Rules)

```bash
# Create the URL path map with both routing rules
az network application-gateway url-path-map create \
  --resource-group $RG \
  --gateway-name $AGW \
  --name appGwUrlPathMap \
  --paths "/app/*" \
  --address-pool appGwAppBackendPool \
  --http-settings appGwAppHttpSettings \
  --default-address-pool appGwAppBackendPool \
  --default-http-settings appGwAppHttpSettings \
  --rule-name AppPathRule

# Add the /api/* rule
az network application-gateway url-path-map rule create \
  --resource-group $RG \
  --gateway-name $AGW \
  --path-map-name appGwUrlPathMap \
  --name ApiPathRule \
  --paths "/api/*" \
  --address-pool appGwApiBackendPool \
  --http-settings appGwApiHttpSettings
```

---

## STEP 9 — Update Routing Rule to Use Path Map

```bash
az network application-gateway rule update \
  --resource-group $RG \
  --gateway-name $AGW \
  --name rule1 \
  --rule-type PathBasedRouting \
  --url-path-map appGwUrlPathMap \
  --http-listener appGatewayHttpListener
```

---

## STEP 10 — Create Custom Data Scripts

Create the cloud-init scripts for both VMSS types (saves them locally first).

```bash
# ── App VMSS cloud-init script ─────────────────────────────────────────────────
cat > /tmp/cloud-init-app.sh << 'SCRIPT'
#!/bin/bash
apt-get update -y
apt-get install -y apache2
systemctl start apache2
systemctl enable apache2
mkdir -p /var/www/html/app
cat > /var/www/html/app/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head><title>Lab 11 - Frontend App (Azure)</title></head>
<body style="font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;text-align:center;padding:50px;">
  <h1 style="color:#0f3460;">&#128196; Frontend App (Azure)</h1>
  <p>Path: <strong>/app/</strong></p>
  <p>Scale Set: <strong>App VMSS</strong></p>
</body>
</html>
HTML
SCRIPT

# ── API VMSS cloud-init script ─────────────────────────────────────────────────
cat > /tmp/cloud-init-api.sh << 'SCRIPT'
#!/bin/bash
apt-get update -y
apt-get install -y apache2
systemctl start apache2
systemctl enable apache2
mkdir -p /var/www/html/api
cat > /var/www/html/api/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head><title>Lab 11 - Backend API (Azure)</title></head>
<body style="font-family:sans-serif;background:#0a0a0a;color:#e0e0e0;text-align:center;padding:50px;">
  <h1 style="color:#e94560;">&#128196; Backend API (Azure)</h1>
  <p>Path: <strong>/api/</strong></p>
  <p>Scale Set: <strong>API VMSS</strong></p>
</body>
</html>
HTML
SCRIPT

# Base64 encode both scripts
APP_CLOUD_INIT=$(base64 -w 0 /tmp/cloud-init-app.sh)
API_CLOUD_INIT=$(base64 -w 0 /tmp/cloud-init-api.sh)
echo "Scripts encoded successfully"
```

---

## STEP 11 — Get Backend Pool IDs

```bash
# Get the App and API backend pool resource IDs
APP_POOL_ID=$(az network application-gateway address-pool show \
  --resource-group $RG \
  --gateway-name $AGW \
  --name appGwAppBackendPool \
  --query id -o tsv)

API_POOL_ID=$(az network application-gateway address-pool show \
  --resource-group $RG \
  --gateway-name $AGW \
  --name appGwApiBackendPool \
  --query id -o tsv)

# Get VMSS Subnet ID
VMSS_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG \
  --vnet-name $VNET \
  --name $VMSS_SUBNET \
  --query id -o tsv)

echo "App Pool ID:  $APP_POOL_ID"
echo "API Pool ID:  $API_POOL_ID"
echo "Subnet ID:    $VMSS_SUBNET_ID"
```

---

## STEP 12 — Create Frontend App VMSS

```bash
az vmss create \
  --resource-group $RG \
  --name $VMSS_APP \
  --location $LOCATION \
  --image Ubuntu2204 \
  --vm-sku Standard_B1s \
  --instance-count 2 \
  --admin-username $ADMIN_USER \
  --admin-password $ADMIN_PASS \
  --authentication-type password \
  --subnet $VMSS_SUBNET_ID \
  --app-gateway $AGW \
  --app-gateway-capacity 2 \
  --backend-pool-name appGwAppBackendPool \
  --custom-data /tmp/cloud-init-app.sh \
  --tags Name=Lab11-App-VMSS \
  --upgrade-policy-mode Automatic \
  --no-wait
```

---

## STEP 13 — Create Backend API VMSS

```bash
az vmss create \
  --resource-group $RG \
  --name $VMSS_API \
  --location $LOCATION \
  --image Ubuntu2204 \
  --vm-sku Standard_B1s \
  --instance-count 2 \
  --admin-username $ADMIN_USER \
  --admin-password $ADMIN_PASS \
  --authentication-type password \
  --subnet $VMSS_SUBNET_ID \
  --app-gateway $AGW \
  --app-gateway-capacity 2 \
  --backend-pool-name appGwApiBackendPool \
  --custom-data /tmp/cloud-init-api.sh \
  --tags Name=Lab11-Api-VMSS \
  --upgrade-policy-mode Automatic \
  --no-wait
```

> ⏳ Wait for both VMSS to provision (~3–5 min). Check status with:
> ```bash
> az vmss list --resource-group $RG --query "[].{Name:name,Capacity:sku.capacity}" -o table
> ```

---

## STEP 14 — Get Public IP & Verify

```bash
# Get the Application Gateway public IP
AGW_IP=$(az network public-ip show \
  --resource-group $RG \
  --name $AGW_PIP \
  --query ipAddress -o tsv)

echo "============================================"
echo " Application Gateway Public IP: $AGW_IP"
echo "============================================"
echo " Frontend App URL : http://$AGW_IP/app/"
echo " Backend API URL  : http://$AGW_IP/api/"
echo "============================================"

# Test with curl
echo ""
echo "Testing /app/ endpoint..."
curl -s http://$AGW_IP/app/ | grep -o '<h1.*</h1>'

echo ""
echo "Testing /api/ endpoint..."
curl -s http://$AGW_IP/api/ | grep -o '<h1.*</h1>'
```

---

## STEP 15 — Cleanup (IMPORTANT — Terminate when done!)

```bash
# Delete everything — Resource Group and all its resources
az group delete \
  --name $RG \
  --yes \
  --no-wait

echo "Cleanup initiated. All Lab11 resources will be deleted."
```

<!-- Output -->
<!-- khan [ ~ ]$ # Get the Application Gateway public IP
AGW_IP=$(az network public-ip show \
  --resource-group $RG \
  --name $AGW_PIP \
  --query ipAddress -o tsv)

echo "============================================"
echo " Application Gateway Public IP: $AGW_IP"
echo "============================================"
echo " Frontend App URL : http://$AGW_IP/app/"
echo " Backend API URL  : http://$AGW_IP/api/"
echo "============================================"

# Test with curl
curl -s http://$AGW_IP/api/ | grep -o '<h1.*</h1>'
============================================
 Application Gateway Public IP: 20.25.85.253
============================================
 Frontend App URL : http://20.25.85.253/app/
 Backend API URL  : http://20.25.85.253/api/
============================================ -->
---

## Quick Reference Summary

| Step | Command | What it Creates |
|------|---------|-----------------|
| 0 | Variables | Reusable names/config |
| 1 | `az group create` | Resource Group |
| 2 | `az network vnet create` + subnet | VNet, VMSS Subnet, AGW Subnet |
| 3 | `az network nsg create` + rules | NSG (Allow HTTP, Health Probe) |
| 4 | `az network public-ip create` | Static Standard IP for AGW |
| 5 | `az network application-gateway create` | Application Gateway |
| 6 | Pool update/create | App & API Backend Pools |
| 7 | HTTP settings update/create | HTTP settings per pool |
| 8 | URL path map create + rule add | `/app/*` and `/api/*` rules |
| 9 | Rule update | Attach path map to routing rule |
| 10 | `cat` + `base64` | Cloud-init scripts |
| 11 | Pool/Subnet ID lookups | IDs needed for VMSS creation |
| 12 | `az vmss create` (App) | Frontend App VMSS (2 instances) |
| 13 | `az vmss create` (API) | Backend API VMSS (2 instances) |
| 14 | `az network public-ip show` | Get IP, test with curl |
| 15 | `az group delete` | **Destroy everything** |

---

> **Note:** Application Gateway Standard_v2 costs roughly **$0.008/hour** + **$0.008 per CU/hour**.  
> Always run **Step 15** after the lab to avoid unexpected charges.
