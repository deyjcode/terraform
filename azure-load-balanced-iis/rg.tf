variable "rgName" {
    default = "aetswebtest-eastus"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "resourcegroup" {
    name     = "${var.rgName}"
    location = "${var.location}"
}

# Generate random text for storage accounts
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.resourcegroup.name}"
    }

    byte_length = 2
}