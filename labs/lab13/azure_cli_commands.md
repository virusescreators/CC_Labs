# Lab 13 – Azure CLI Implementation Guide
## Continuous Deployment on Azure (Web App Local Git & GitHub Actions)

This guide demonstrates how to configure **Continuous Deployment (CI/CD)** on Azure using the **Azure CLI**. 

We present two modern approaches to setting up automated deployment pipelines for a web application:
1. **Option A (Built-in CD):** Deploying via **App Service Local Git** (pushing to an Azure Git remote triggers automatic builds and hosting).
2. **Option B (Enterprise CI/CD):** Deploying via **GitHub Actions** (triggering automated workflows on every git push using a secure Azure Service Principal).

> Run all commands in **Azure Cloud Shell** (bash) or a local terminal with the `az` CLI installed and logged in.

---

## **STEP 0 — Login & Set Variables**

```bash
# Login to Azure (skip if already logged in via Cloud Shell)
az login

# ── Set all reusable variables ────────────────────────────────────────────────
RG="Lab13-CD-RG"
LOCATION="eastus"
PLAN="Lab13-AppPlan"
WEBAPP="lab13-webapp-$RANDOM"   # App names must be globally unique
GIT_USER="azuredeployuser"      # Username for deployment credentials
GIT_PASS="Lab13P@ssw0rd!"       # Change this to a secure password
```

---

## **STEP 1 — Create Resource Group**

```bash
az group create \
  --name $RG \
  --location $LOCATION
```

---

## **OPTION A — Continuous Deployment via Azure Web App Local Git**

This option configures a Git endpoint hosted inside Azure. Pushing code to this remote repository automatically builds and runs the application.

### **Step A.1 — Create App Service Plan**
Create an App Service Plan specifying the target operating system (Linux) and pricing tier (Free `F1` or cost-efficient `B1`).

```bash
az appservice plan create \
  --resource-group $RG \
  --name $PLAN \
  --location $LOCATION \
  --sku B1 \
  --is-linux
```

### **Step A.2 — Create the Web App**
Provision a Linux Web App. We will use the Node.js 18 runtime to automatically build and host modern JavaScript/React web apps.

```bash
az webapp create \
  --resource-group $RG \
  --plan $PLAN \
  --name $WEBAPP \
  --runtime "NODE:18-lts"
```

### **Step A.3 — Configure Deployment User & Git Source**
Set up global deployment credentials (used to push code to Azure) and enable the Local Git deployment option on the Web App.

```bash
# 1. Set global deployment credentials
az webapp deployment user set \
  --user-name $GIT_USER \
  --password $GIT_PASS

# 2. Configure Web App to accept Git deployment
DEPLOY_URL=$(az webapp deployment source config-local-git \
  --resource-group $RG \
  --name $WEBAPP \
  --query url -o tsv)

echo "============================================"
echo " Azure Git Remote Deployment URL: $DEPLOY_URL"
echo "============================================"
```

### **Step A.4 — Push Application Code to Deploy**
Now you can initialize a local Git repository, add the Azure Git remote, and push your web application to trigger the build pipeline.

```bash
# 1. Initialize local repository
git init
git add .
git commit -m "Initial commit for Lab 13 CI/CD"

# 2. Add Azure Git Remote
git remote add azure $DEPLOY_URL

# 3. Push and Deploy (Enter GIT_PASS when prompted)
git push azure master
```

---

## **OPTION B — Continuous Integration & Deployment via GitHub Actions**

This option implements a production-grade CI/CD pipeline using **GitHub Actions**. Every push to your GitHub repository triggers a workflow that builds your project and securely deploys it to your Azure Web App.

### **Step B.1 — Create Azure Service Principal (Credentials)**
GitHub needs permissions to push code to your Azure Resource Group. We will create a secure, role-based Service Principal and get the authentication credentials.

```bash
# 1. Retrieve the Resource Group ID
RG_ID=$(az group show --name $RG --query id -o tsv)

# 2. Create the Service Principal
az ad sp create-for-rbac \
  --name "Lab13-GitHub-CI-CD" \
  --role contributor \
  --scopes $RG_ID \
  --json-auth
```

> [!WARNING]
> This command outputs a JSON object containing credentials. Copy the **entire** JSON block. It looks like this:
> ```json
> {
>   "clientId": "<GUID>",
>   "clientSecret": "<SECRET>",
>   "subscriptionId": "<GUID>",
>   "tenantId": "<GUID>",
>   ...
> }
> ```

### **Step B.2 — Configure GitHub Repository Secrets**
1. Navigate to your project repository on GitHub.
2. Go to **Settings** > **Secrets and variables** > **Actions**.
3. Click **New repository secret**.
4. Set the **Name** to `AZURE_CREDENTIALS`.
5. Paste the **entire JSON block** copied from Step B.1 into the **Value** field and save.

---

### **Step B.3 — Create the GitHub Actions Workflow File**
Create a directory structure `.github/workflows/` in the root of your local repository. Within it, create a file named `deploy.yml`:

```yaml
name: Deploy Web Application to Azure

on:
  push:
    branches:
      - main
      - master

permissions:
  contents: read

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install Dependencies & Build
        run: |
          npm install
          npm run build --if-present

      - name: Log in to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets::AZURE_CREDENTIALS }}

      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ env.AZURE_WEBAPP_NAME }} # Replace with your variable
          package: .
```

*Note: Make sure to replace the App Name in the workflow or define a top-level environment variable:*
```yaml
env:
  AZURE_WEBAPP_NAME: 'your-globally-unique-webapp-name'
```

---

### **Step B.4 — Commit & Push to Trigger CI/CD Pipeline**
```bash
git add .
git commit -m "Add GitHub Actions CI/CD pipeline configuration"
git push origin main
```
Navigate to the **Actions** tab on your GitHub repository to watch your automated build and deployment run in real time!

---

## **STEP 4 — Verify the Deployment**

Retrieve the public web endpoint of your Azure Web App:

```bash
WEBAPP_URL=$(az webapp show \
  --resource-group $RG \
  --name $WEBAPP \
  --query defaultHostName -o tsv)

echo "================================================="
echo " Verify Web Application: http://$WEBAPP_URL"
echo "================================================="
```

---

## **STEP 5 — Cleanup (IMPORTANT — Terminate when done!)**

To avoid incurring charges, delete the resource group. This automatically destroys all hosted services (App Service Plan, Web App, Deployment Slots, etc.).

```bash
az group delete \
  --name $RG \
  --yes \
  --no-wait

echo "Cleanup initiated. All Lab13 Azure resources will be deleted."
```

---

## **Quick Reference Summary**

| Phase | Azure CLI Command | Description |
| :--- | :--- | :--- |
| **Setup** | `az group create` | Provisions a dedicated Lab Resource Group. |
| **Option A** | `az appservice plan create` | Provisions a Linux hosting server layer. |
| **Option A** | `az webapp create` | Provisions the Web Hosting App Service instance. |
| **Option A** | `az webapp deployment source config-local-git` | Sets up a local Git build-and-deploy endpoint. |
| **Option B** | `az ad sp create-for-rbac` | Creates a secure Service Principal to authorize GitHub Actions. |
| **Verify** | `az webapp show` | Fetches the public domain URL of the web server. |
| **Cleanup** | `az group delete` | **Destroys all resources** immediately. |
