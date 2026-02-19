# Azure Setup for Labs

To run the labs on Azure, you need to configure your Azure environment and GitHub repository secrets.

## Prerequisites

1.  **Azure Account**: You need an active Azure subscription.
2.  **Azure CLI**: Install the Azure CLI locally if you want to run Terraform locally.

## Azure Service Principal Setup

The GitHub Actions workflow uses an Azure Service Principal to authenticate.

1.  **Login to Azure CLI**:
    ```bash
    az login
    ```

2.  **Create Service Principal**:
    Replace `<SUBSCRIPTION_ID>` with your subscription ID.
    ```bash
    az ad sp create-for-rbac --name "github-actions-lab-deployer" --role Contributor --scopes /subscriptions/<SUBSCRIPTION_ID> --sdk-auth
    ```

    *Note: For Lab 01 (Azure AD User creation), you might need additional API permissions.*
    To grant Azure AD permissions:
    ```bash
    # Get the SP ObjectId
    SP_ID=$(az ad sp list --display-name "github-actions-lab-deployer" --query "[0].id" -o tsv)

    # Graph API ID for User.ReadWrite.All (Example, consult MS Docs for exact UUIDs)
    # This part is complex to script safely; easiest to do in Portal:
    # Go to Entra ID -> App Registrations -> [Your App] -> API Permissions -> Add -> Microsoft Graph -> Application -> User.ReadWrite.All -> Grant Admin Consent
    ```

3.  **Save Output JSON**:
    The command in step 2 (without `--sdk-auth` for newer versions, or with it for compatibility) outputs JSON with `clientId`, `clientSecret`, `subscriptionId`, `tenantId`.

## GitHub Secrets Configuration

Go to your GitHub Repository -> Settings -> Secrets and variables -> Actions -> New repository secret.

Add the following secrets:

-   `AZURE_CLIENT_ID`: The `clientId` from the JSON output.
-   `AZURE_CLIENT_SECRET`: The `clientSecret` from the JSON output.
-   `AZURE_SUBSCRIPTION_ID`: The `subscriptionId` from the JSON output.
-   `AZURE_TENANT_ID`: The `tenantId` from the JSON output.

-   `TF_STATE_BUCKET`: (Existing) S3 bucket for state.
-   `TF_LOCK_TABLE`: (Existing) DynamoDB table for locking.
-   `AWS_ACCESS_KEY_ID`: (Existing) AWS Access Key.
-   `AWS_SECRET_ACCESS_KEY`: (Existing) AWS Secret Key.

## Running the Labs

1.  Go to the "Actions" tab in your repository.
2.  Select "Deploy Labs".
3.  Click "Run workflow".
4.  Select the **Lab Number**.
5.  Select the **Cloud Provider** (`azure` or `aws`).
6.  Select the **Action** (`apply` or `destroy`).
