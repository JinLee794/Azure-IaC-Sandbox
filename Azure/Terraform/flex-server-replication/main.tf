terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~>4.0"
        }
    }
}

provider "azurerm" {
    subscription_id = var.subscription_id
    features {
        resource_group {
            prevent_deletion_if_contains_resources = false
         }
    }
}

#######################################

resource "azurerm_resource_group" "primary" {
    name     = var.primary_resource_group_name
    location = var.primary_location
}

resource "azurerm_resource_group" "secondary" {
    name     = var.secondary_resource_group_name
    location = var.secondary_location
}

resource "azurerm_mysql_flexible_server" "primary" {
    name                = var.primary_server_name
    resource_group_name = azurerm_resource_group.primary.name
    location            = azurerm_resource_group.primary.location
    administrator_login = var.administrator_login
    administrator_password = var.administrator_password

    storage {
        size_gb = var.storage_size_gb
    }

    sku_name   = var.sku_name
    geo_redundant_backup_enabled = false

    tags = var.tags
}

resource "azurerm_mysql_flexible_server" "replica" {
    name                = var.secondary_server_name

    resource_group_name = var.replica_exists ? azurerm_resource_group.secondary.name : azurerm_resource_group.primary.name
    location            = azurerm_resource_group.secondary.location 
    source_server_id    = azurerm_mysql_flexible_server.primary.id
    create_mode         = var.replica_exists ? null : "Replica"

    tags = var.tags
}