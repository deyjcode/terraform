# Create virtual network
resource "azurerm_virtual_network" "network" {
    name                = "webtest-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"

    tags {
        environment = "webtest"
    }
}

# Create webapp subnet
resource "azurerm_subnet" "websub1" {
    name                 = "webapptest-subnet"
    resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix       = "10.0.0.0/24"
}

# Create frontend app gateway subnet
resource "azurerm_subnet" "appgw1subnetfe" {
    name                 = "appgw1test-subnet"
    resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix       = "10.0.1.0/28"
}

# Create backend app gateway subnet
resource "azurerm_subnet" "appgw1subnetbe" {
    name                 = "appgw1test-subnet-be"
    resource_group_name  = "${azurerm_resource_group.resourcegroup.name}"
    virtual_network_name = "${azurerm_virtual_network.network.name}"
    address_prefix       = "10.0.2.0/28"
}