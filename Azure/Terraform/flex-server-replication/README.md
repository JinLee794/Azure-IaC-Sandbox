# Flex Server Replication Deployment

This project automates the deployment and management of Azure MySQL Flexible Servers, including the creation of primary and replica servers, and the movement of replicas between resource groups using Terraform and Azure CLI.
> **Disclaimer**: This project provides a custom workaround for managing MySQL Flexible Server replication. Users of this script must take full ownership of the lifecycle and management of the resources created. Please note that native functionality for MySQL Flexible Server replication is targeted for mid FY 2025.
## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- Azure subscription with appropriate permissions

## Project Structure

- `main.tf`: Defines the Terraform configuration for creating primary and replica MySQL Flexible Servers.
- `variables.tf`: Contains the variables used in the Terraform configuration.
- `deploy.sh`: Shell script to initialize and apply the Terraform configuration, and move the replica if necessary.
- `replica.sh`: Shell script to move the replica to the target resource group and update the Terraform state.

## Deployment Steps

1. **Set Environment Variables**: Update the values in `deploy.sh` with your own configuration or provide them when prompted.

    [./deploy.sh](./deploy.sh)
    ```bash 
    #!/bin/bash

    ## Update these values with your own
    # Primary Config
    primary_resource_group="flex-primary"
    primary_location="South Central US"
    primary_server_name="example-primary-mysql"

    # Desired Replica Config
    target_location="West US"
    target_resource_group="flex-secondary"
    target_server_name="example-replica-mysql-westus"

    # To be able to map to the Terraform resource in the tfstate to import
    tf_resource_id="azurerm_mysql_flexible_server.replica"
    ```

    You can also set the environment variables using `TF_VAR` notation (i.e within a CICD pipeline) to minimize accidental recreates or unnecessary updates.

    ```bash
    export TF_VAR_administrator_login="myAdminUser"
    # export TF_VAR_administrator_password="<your password here>"
    ```



2. **Initialize and Apply Terraform Configuration**:
    ```sh
    ./deploy.sh
    ```
    This script will:
    - Initialize Terraform.
    - Check if the replica exists in the target resource group via the `az cli`.
        - if not, sets the flag `TF_VAR_replica_exists` to `false`
        - otherwise, sets the flag `TF_VAR_replica_exists` to `true`
    - Apply the Terraform configuration to create the primary and replica MySQL Flexible Servers.
    - If the replica does not exist in the target rg, it will move the replica to the target resource group and update the Terraform state.
    
        > **Note**: The `var.replica_exists` flag in the `azurerm_mysql_flexible_server` replica configuration (lines 48-57) is crucial for ensuring the Terraform deployment properly recognizes the resource in the `tfstate` after it has been moved by `./replica.sh`. 

3. **Verify Terraform State**:
    After running the deployment script, the Terraform state will be verified to ensure no changes are detected.

## Scripts

### [deploy.sh](http://_vscodecontentref_/1)

This script performs the following actions:
- Sets environment variables from Terraform variables.
- Initializes Terraform.
- Applies the Terraform configuration.
- Runs the [replica.sh](http://_vscodecontentref_/2) script to move the replica if necessary.
- Verifies the Terraform state.

### [replica.sh](http://_vscodecontentref_/3)

This script performs the following actions:
- Checks if the replica needs to be moved.
- Moves the replica to the target resource group.
- Captures the new resource in the Terraform state via import.
- Sets the environment variable `TF_VAR_replica_exists` to `true`.

## Example Usage

```sh
./deploy.sh
```