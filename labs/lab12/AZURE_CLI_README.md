# Lab 12: Deployment on Azure using Azure CLI

This guide demonstrates how to deploy the Lab 12 infrastructure (a React application hosted on an Nginx server) using the **Azure CLI**. You can perform these steps directly within the [Azure Cloud Shell](https://shell.azure.com/).

## Step 1: Create a Resource Group

First, create a resource group to hold your resources.

```bash
az group create --name Lab12-CLI-RG --location eastus
```

## Step 2: Prepare the Cloud-Init Script

We need a script to automate the installation of Node.js, Nginx, and our React app when the virtual machine starts.

Create a file named `cloud-init.txt` in your Cloud Shell (for example, by running `nano cloud-init.txt`) and paste the following content:

```yaml
#cloud-config
package_upgrade: true
packages:
  - nginx
  - git
  - curl

runcmd:
  - curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  - apt-get install -y nodejs
  - cd /home/azureuser
  - npx create-react-app@latest react-app
  - cd react-app
  - npm run build
  - rm -rf /var/www/html/*
  - cp -r build/* /var/www/html/
  - systemctl restart nginx
  - systemctl enable nginx
```

Save and close the file.

## Step 3: Create the Virtual Machine

Use the `az vm create` command to deploy an Ubuntu 22.04 LTS VM. We will pass the `cloud-init.txt` file we just created so the VM automatically configures the React app.

```bash
az vm create \
  --resource-group Lab12-CLI-RG \
  --name Lab12-React-VM \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data cloud-init.txt \
  --size Standard_D2s_v3 \
  --public-ip-sku Standard
```

## Step 4: Open Port 80 for Web Traffic

By default, the virtual machine only opens port 22 (SSH). To access the React app via a web browser, open port 80 (HTTP).

```bash
az vm open-port --port 80 --resource-group Lab12-CLI-RG --name Lab12-React-VM
```

## Step 5: Verify the Deployment

Get the Public IP address of the Virtual Machine by running:

```bash
az vm show \
  --resource-group Lab12-CLI-RG \
  --name Lab12-React-VM \
  --show-details \
  --query publicIps \
  --output tsv
```

Wait a few minutes for the cloud-init script to finish installing Node.js and building the React app. Then, open a web browser and navigate to `http://<YOUR_PUBLIC_IP>`. You should see the default React application running!

## Step 6: Clean Up Resources

Once you are done exploring, delete the resource group to avoid incurring charges.

```bash
az group delete --name Lab12-CLI-RG --yes --no-wait
```
