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

# Function to prompt for input if a variable is not set
prompt_for_input() {
    local var_name=$1
    local prompt_message=$2
    local is_secret=$3

    if [ -z "${!var_name}" ]; then
        if [ "$is_secret" = true ]; then
            read -s -p "$prompt_message: " $var_name
            echo
        else
            read -p "$prompt_message: " $var_name
        fi
        export $var_name
    fi
}

# Function to check if the replica exists in the Terraform state
check_replica_exists() {
    terraform state show "$tf_resource_id" 2>/dev/null | grep -q "resource_group_name *= *\"$target_resource_group\"" && echo "true" || echo ""
}

# Display deployment information
display_info() {
    echo "========================================"
    echo "          Starting Deployment           "
    echo "========================================"
    echo
    echo "Primary Resource Group: $primary_resource_group"
    echo "Primary Location: $primary_location"
    echo "Primary Server Name: $primary_server_name"
    echo 
    echo "Target Resource Group: $target_resource_group"
    echo "Target Location: $target_location"
    echo "Target Server Name: $target_server_name"
    echo
}

# Main script execution
main() {
    display_info

    # Set environment variables from Terraform variables
    TF_VAR_subscription_id=$(az account show --query id --output tsv 2>/dev/null)
    prompt_for_input "TF_VAR_subscription_id" "Enter your subscription ID"
    prompt_for_input "TF_VAR_administrator_login" "Enter your administrator login"
    prompt_for_input "TF_VAR_administrator_password" "Enter your administrator password" true

    export TF_VAR_primary_resource_group_name=$primary_resource_group
    export TF_VAR_primary_location=$primary_location
    export TF_VAR_primary_server_name=$primary_server_name

    export TF_VAR_secondary_resource_group_name=$target_resource_group
    export TF_VAR_secondary_location=$target_location
    export TF_VAR_secondary_server_name=$target_server_name

    # export TF_VAR_storage_size_gb=20
    # export TF_VAR_sku_name="GP_Standard_D2ds_v4"

    # Check if the replica exists
    echo "----------------------------------------"
    echo "Checking if the replica exists in the Terraform state..."
    echo "----------------------------------------"
    replica_exists=$(check_replica_exists)

    if [ -z "$replica_exists" ]; then
        echo "Replica does not exist in the target resource group."
        echo "Setting TF_VAR_replica_exists to false."
        export TF_VAR_replica_exists=false
    else
        echo "Replica exists in the target resource group."
        echo "Setting TF_VAR_replica_exists to true."
        export TF_VAR_replica_exists=true
    fi
    echo

    # Initialize and deploy first
    echo "----------------------------------------"
    echo "Initializing Terraform..."
    echo "----------------------------------------"
    terraform init
    echo

    echo "----------------------------------------"
    echo "Applying Terraform configuration..."
    echo "----------------------------------------"
    terraform apply

    # Move the replica, capture the state and set the ENV Var to CREATE_REPLICA to false
    echo "----------------------------------------"
    echo "Running replica move script..."
    echo "----------------------------------------"
    ./replica.sh $primary_resource_group $primary_server_name $target_resource_group $target_server_name $tf_resource_id
    echo

    # Verify the state has been captured (expected result: no changes detected)
    echo "----------------------------------------"
    echo "Verifying Terraform state..."
    echo "----------------------------------------"
    terraform plan
    echo

    echo "========================================"
    echo "        Deployment Completed            "
    echo "========================================"
}

# Run the main function
main