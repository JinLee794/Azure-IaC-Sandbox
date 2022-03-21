variable "name" {
    type = string
}
variable "resource_group_name" {
    type = string
}
variable "location" {
    type = string
}
variable "tags" {
    type = map(string)
    default = {}
}

variable "admin_username" {
    type = string
}
variable "admin_password_secret_name" {
    type = string
}


variable "law_key_vault_name" {
    type = string
}
variable "law_key_vault_rg_name" {
    type = string
}
variable "law_key_name" {
    type = string
}
variable "law_id" {
    type = string
}

variable "vm_name" {
    type = string
}

variable "env" {
    type = string
}
variable "subnet_id" {
    type = string
}

