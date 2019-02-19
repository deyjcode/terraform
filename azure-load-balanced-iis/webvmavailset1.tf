resource "azurerm_availability_set" "webtestavail1" {
    name                = "webtestavailset1"
    location            = "${var.location}"
    resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
    managed             = true
}