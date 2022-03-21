
data "azurerm_key_vault" "this" {
  name                = var.law_key_vault_name
  resource_group_name = var.law_key_vault_rg_name
}

data "azurerm_key_vault_secret" "law-win-agent-key" {
  name         = var.law_key_name
  key_vault_id = data.azurerm_key_vault.this.id
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = var.admin_password_secret_name
  key_vault_id = data.azurerm_key_vault.this.id
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-${var.vm_name}-pdp-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.vm_name}-ip-vm-internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "dynamic"
  }
}


resource "azurerm_windows_virtual_machine" "this" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  size                       = "Standard_F4"
  tags                       = var.tags
  timezone                   = "GMT Standard Time"
  enable_automatic_updates   = true
  patch_mode                 = "AutomaticByOS"
  provision_vm_agent         = true
  admin_username             = var.admin_username
  admin_password             = data.azurerm_key_vault_secret.admin_password.value
  
  computer_name              = var.vm_name
  allow_extension_operations = true
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
  timeouts {
    create = "90m"
    delete = "90m"
  }
}


resource "azurerm_virtual_machine_extension" "IaaSAntimalware" {
  // count = var.extensions_type_list
  name                 = "${var.name}-IaaSAntimalware"
  virtual_machine_id   = azurerm_windows_virtual_machine.this.id
  publisher            = "Microsoft.Azure.Security"
  type                 = "IaaSAntimalware"
  type_handler_version = "1.5"
  tags = var.tags
}


resource "azurerm_virtual_machine_extension" "DependencyAgentWindows" {
  // count = var.extensions_type_list
  name                 = "${var.name}-DependencyAgentWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.this.id
  publisher            = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                 = "DependencyAgentWindows"
  type_handler_version = "9.10"

  settings = <<SETTINGS
    {
        "workspaceId": "${var.law_id}"
    }
SETTINGS

  protected_settings = <<SETTINGS
    {
        "workspaceKey": "${data.azurerm_key_vault_secret.law-win-agent-key.value}"
    }
SETTINGS

  tags = var.tags
}


resource "azurerm_virtual_machine_extension" "MicrosoftMonitoringAgent" {
  // count = var.extensions_type_list
  name                 = "${var.name}-MicrosoftMonitoringAgent"
  virtual_machine_id   = azurerm_windows_virtual_machine.this.id
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = "MicrosoftMonitoringAgent"
  type_handler_version = "1.0"

  settings = <<SETTINGS
    {
        "workspaceId": "${var.law_id}"
    }
SETTINGS

  protected_settings = <<SETTINGS
    {
        "workspaceKey": "${data.azurerm_key_vault_secret.law-win-agent-key.value}"
    }
SETTINGS

  tags = var.tags
}


resource "azurerm_virtual_machine_extension" "ConfigurationforWindows" {
  // count = var.extensions_type_list
  name                 = "${var.name}-ConfigurationforWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.this.id
  publisher            = "Microsoft.GuestConfiguration"
  type                 = "ConfigurationforWindows"
  type_handler_version = "1.29"

  settings = <<SETTINGS
    {
        "workspaceId": "${var.law_id}"
    }
SETTINGS

  tags = var.tags
}


resource "azurerm_virtual_machine_extension" "NetworkWatcherAgentWindows" {
  // count = var.extensions_type_list
  name                 = "${var.name}-NetworkWatcherAgentWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.this.id
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentWindows"
  type_handler_version = "1.4"

  settings = <<SETTINGS
    {
        "workspaceId": "${var.law_id}"
    }
SETTINGS

  tags = var.tags
}
