terraform {
  required_providers {
      azapi = {
        source = "Azure/azapi"
        version = "~>2.0"
      }
  }
}

provider "azapi" {
  enable_preflight = true
}

data "azapi_client_config" "current" {}

# =================================
# 1. Dynamic Properties/Clarity with Outputs
# =================================

resource "azapi_resource" "resourceGroup" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  
  name      = "example-resource-group"
  location  = "westeurope"
  body = {
    properties = {}
  }
}

# =================================
# 2. Preflight Support
# =================================
resource "azapi_resource" "vnet" {
  type      = "Microsoft.Network/virtualNetworks@2024-01-01"
  parent_id = azapi_resource.resourceGroup.id
  name      = "example-vnet"
  location  = "westus"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = [
          "10.0.0.0/16",  // Note: Invalid CIDR block, preflight will throw an error here
        ]
      }
    }
  }
}

# =================================
# 3. Customized Retry
# =================================

// Example: Lookup a resource that doesn't exist
data "azapi_resource" "test" {
  type = "Microsoft.Resources/resourceGroups@2024-03-01"
  name = "example"

  retry = {
    error_message_regex  = ["ResourceGroupNotFound"]
    interval_seconds     = 5
    max_interval_seconds = 30
    multiplier           = 1.5
    randomization_factor = 0.5
  }
}

# =================================
# 4. Resource Replacement Triggers
# =================================

variable "replace" {
  type = bool
  default = true
}


resource "azapi_resource" "automationAccountv2" {
  type      = "Microsoft.Automation/automationAccounts@2023-11-01"
  parent_id = azapi_resource.resourceGroup.id
  name      = "example-automation-account"
  location  = "westeurope"
  body = {
    properties = {
      encryption = {
        keySource = "Microsoft.Automation"
      }
      publicNetworkAccess = true
      sku = {
        name = "Basic"
      }
    }
  }

  // native lifecycle management
  lifecycle {
    ignore_changes = [
      body.properties.encryption.keySource
    ]
  }
  // The replace_triggers_external_values attribute will trigger a resource replacement when the 
  //  value changes and is not null.
  replace_triggers_external_values = [
    var.replace,
  ]

  // The replace_triggers_refs attribute accepts a list of JMESPath expressions that query the 
  //  resource attributes. The resource will be replaced when the query result changes.
  replace_triggers_refs = [
    "zones",
  ]
  response_export_values = ["properties"]
}


output "o1v2automationHybridServiceUrl" {
  // it's not necessary to use `jsondecode` function to decode the response
  value = azapi_resource.automationAccountv2.output.properties.automationHybridServiceUrl
}

output "o1v2pwsh" {
  value = azapi_resource.automationAccountv2.output.properties.RuntimeConfiguration.powershell
}

output "o1v2output" {
  value = azapi_resource.automationAccountv2.output
}

# =================================
# 5. Resource Discovery
# =================================
data "azapi_resource_list" "listVirtualMachinesBySubscription" {
  type      = "Microsoft.Compute/virtualMachines@2020-06-01"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"


  // The output attribute contains the result of the query, if default output is enabled(default output feature is 
  //  introduced and by default enabled in version 2.1.0, you can disable it by setting disable_default_output = true):
  # disable_default_output = true
}

output "subscriptionVMs" {
  value = data.azapi_resource_list.listVirtualMachinesBySubscription.output
}

