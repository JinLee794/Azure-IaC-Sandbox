primary_resource_group=$1
primary_server_name=$2
target_resource_group=$3
target_server_name=$4
tf_resource_id=$5

echo "Primary Resource Group: $primary_resource_group"
echo "Primary Server Name: $primary_server_name"
echo "Target Resource Group: $target_resource_group"
echo "Target Server Name: $target_server_name"
echo "Terraform Resource ID: $tf_resource_id"
echo
echo "========================================"
echo "       Starting Replica Move Script     "
echo "========================================"
echo

# 1. Check if the replica needs to be moved
echo "----------------------------------------"
echo "Checking if the replica needs to be moved..."
echo "----------------------------------------"
replica_id=$(az mysql flexible-server replica list --resource-group $primary_resource_group \
                                                            -n $primary_server_name \
                                                            --query "[?name=='$target_server_name'].id" --output tsv)

if [ -z "$replica_id" ]; then
    echo "No replica found with the name $target_server_name within the primary server: $primary_server_name."
    exit 1
fi

current_resource_group=$(az resource show --ids $replica_id --query 'resourceGroup' --output tsv)
echo "Current Resource Group of the replica: $current_resource_group"
echo "Desired Target Resource Group for the replication: $target_resource_group"
echo

if [ "$current_resource_group" == "$target_resource_group" ]; then
    echo "Replica is already in the target resource group. No action needed."
    exit 0
fi

# 2. Move to the target resource group
echo "----------------------------------------"
echo "Moving replica to the target resource group..."
echo "----------------------------------------"
# Wait until any ongoing deployments are finished
echo "Waiting for any ongoing deployments to finish..."
while true; do
    ongoing_deployments=$(az deployment group list --resource-group $primary_resource_group --query "[?properties.provisioningState=='Running']" --output tsv)
    if [ -z "$ongoing_deployments" ]; then
        break
    fi
    echo "Ongoing deployments detected in $primary_resource_group. Waiting for 30 seconds..."
    sleep 30
done

# Move the replica to the target resource group
echo "Moving the replica to the target resource group..."


az resource move --destination-group $target_resource_group --ids $replica_id
if [ $? -ne 0 ]; then
    echo "Failed to move the replica to the target resource group."
    exit 1
fi
echo "Replica moved successfully."
echo

# 3. Capture the new resource in the tf state via import
echo "----------------------------------------"
echo "Importing the moved replica into Terraform state..."
echo "----------------------------------------"
attempt=0
max_attempts=3
while [ $attempt -le $max_attempts ]; do
    moved_replica_id=$(az mysql flexible-server replica list --resource-group $primary_resource_group \
                                                                -n $primary_server_name \
                                                                --query "[?name=='$target_server_name'].id" --output tsv)
    if [ -n "$moved_replica_id" ]; then
        break
    fi
    attempt=$((attempt + 1))
    if [ $attempt -le $max_attempts ]; then
        echo "Failed to retrieve the moved replica ID. Retrying in 15 seconds... (Attempt $attempt/$max_attempts)"
        sleep 15
    fi
done

if [ -z "$moved_replica_id" ]; then
    echo "Failed to retrieve the moved replica ID."
    exit 1
fi

terraform state rm $tf_resource_id || echo "Terraform state rm failed, but continuing..."
terraform import $tf_resource_id $moved_replica_id || echo "Terraform import failed, but continuing..."
echo "Terraform import completed."
echo

# Set the ENV Var to CREATE_REPLICA to false, which will enable the resource on Terraform.
export TF_VAR_replica_exists="true"
echo "Environment variable TF_VAR_replica_exists set to true."
echo

echo "========================================"
echo "       Replica Move Script Completed    "
echo "========================================"