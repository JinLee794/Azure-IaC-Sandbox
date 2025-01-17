
variable "subscription_id" {
    description = "The subscription ID for the Azure provider."
    default     = "63862159-43c8-47f7-9f6f-6c63d56b0e17"
}

variable "replica_exists" {
  description = "Flag to indicate if the replica already exists."
  default     = false
}

variable "tags" {
    description = "Tags to be applied to resources."
    default = {
        hidden-title = "Flex Server Replication Workaround Test"
    }
}

variable "primary_resource_group_name" {
    description = "The name of the primary resource group."
    default     = "flex-primary"
}

variable "primary_location" {
    description = "The location of the primary resource group."
    default     = "South Central US"
}

variable "secondary_resource_group_name" {
    description = "The name of the secondary resource group."
    default     = "flex-secondary"
}

variable "secondary_location" {
    description = "The location of the secondary resource group."
    default     = "West US"
}

variable "primary_server_name" {
    description = "The name of the primary MySQL flexible server."
    default     = "example-primary-mysql"
}

variable "secondary_server_name" {
    description = "The name of the primary MySQL flexible server."
    default     = "example-secondary-mysql"
}

variable "administrator_login" {
    description = "The administrator login for the MySQL flexible server."
    default     = "mysqladminun"
}

variable "administrator_password" {
    description = "The administrator password for the MySQL flexible server."
    default     = "H@Sh1CoR3!"
}

variable "storage_size_gb" {
    description = "The storage size in GB for the MySQL flexible server."
    default     = 20
}

variable "sku_name" {
    description = "The SKU name for the MySQL flexible server."
    default     = "GP_Standard_D2ds_v4"
}