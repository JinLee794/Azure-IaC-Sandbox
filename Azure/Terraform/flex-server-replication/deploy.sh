primary_resource_group="flex-primary"
primary_server_name="example-primary-mysql"
target_resource_group="flex-secondary"
target_server_name="example-replica-mysql-westus"
tf_resource_id="azurerm_mysql_flexible_server.replica"

echo "========================================"
echo "          Starting Deployment           "
echo "========================================"
echo
echo "Primary Resource Group: $primary_resource_group"
echo "Target Resource Group: $target_resource_group"
echo "Primary Server Name: $primary_server_name"
echo "Target Server Name: $target_server_name"
echo

# Set environment variables from Terraform variables
## Update these values with your own
# Attempt to get the subscription ID from the current Azure account
TF_VAR_subscription_id=$(az account show --query id --output tsv 2>/dev/null)

# If the subscription ID is not retrieved, prompt the user to enter it
if [ -z "$TF_VAR_subscription_id" ]; then
    read -p "Enter your subscription ID: " TF_VAR_subscription_id
fi
export TF_VAR_subscription_id

if [ -z "$TF_VAR_administrator_login" ]; then
    read -p "Enter your administrator login: " TF_VAR_administrator_login
    export TF_VAR_administrator_login
fi

if [ -z "$TF_VAR_administrator_password" ]; then
    read -s -p "Enter your administrator password: " TF_VAR_administrator_password
    echo
    export TF_VAR_administrator_password
fi

## Optionally update these values according to your preference
export TF_VAR_primary_resource_group_name="flex-primary"
export TF_VAR_primary_location="South Central US"
export TF_VAR_secondary_resource_group_name="flex-secondary"
export TF_VAR_secondary_location="West US"
export TF_VAR_primary_server_name="example-primary-mysql"
export TF_VAR_secondary_server_name="example-replica-mysql-westus"
export TF_VAR_storage_size_gb=20
export TF_VAR_sku_name="GP_Standard_D2ds_v4"

# Check if the replica exists
echo "----------------------------------------"
echo "Checking if the replica exists in the Terraform state..."
echo "----------------------------------------"
replica_exists=$(terraform state show "$tf_resource_id" 2>/dev/null | grep -q "resource_group_name *= *\"$target_resource_group\"" && echo "true" || echo "")

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
terraform apply -auto-approve 

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