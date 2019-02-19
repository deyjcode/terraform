# Prompt user for values
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "admin_username" {}
variable "admin_password" {}

# Location of resources to be deployed to
variable "location" {
    default = "East US 2"
}

# Assign variables for the vms
variable "osDiskType" {
    default = "Premium_LRS"
}

# Enter rgname for image name
variable "custom_image_resource_group_name" {
  default = ""
}

# Enter image name
variable "custom_image_name" {
  default = ""
}

# Prompt for password for SSL Certificate
variable "ssl_certificate_password" {
    default = ""
}

# Grab Packer Image for vms - don't change this 
data "azurerm_image" "customimage" {
    name                = "${var.custom_image_name}"
    resource_group_name = "${var.custom_image_resource_group_name}"
}