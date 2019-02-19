# Configuration for network load balancer (Layer 4)
resource "azurerm_public_ip" "lb1PublicIP" {
  name                         = "lbtest1PublicIP"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
  allocation_method            = "Static"
  tags {
      environment = "webtest"
  }
}

# Create the load balancer
resource "azurerm_lb" "lb1testweb" {
  name                         = "lb1webtest"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"

  frontend_ip_configuration {
    name                 = "lb1FEIpConfig"
    public_ip_address_id = "${azurerm_public_ip.lb1PublicIP.id}"
  }
}

# Create the backend pool
resource "azurerm_lb_backend_address_pool" "lb1testwebbepool" {
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  loadbalancer_id     = "${azurerm_lb.lb1testweb.id}"
  name                = "lb1BeAddrPool"
}

resource "azurerm_lb_nat_rule" "lb1testnatrule" {
  resource_group_name            = "${azurerm_resource_group.resourcegroup.name}"
  loadbalancer_id                = "${azurerm_lb.lb1testweb.id}"
  name                           = "RDPAccess"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  frontend_ip_configuration_name = "lb1FEIpConfig"
}

resource "azurerm_lb_probe" "lb1testproberdp" {
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  loadbalancer_id     = "${azurerm_lb.lb1testweb.id}"
  name                = "rdp-running-probe"
  port                = 3389
}

resource "azurerm_lb_probe" "lb1testprobessh" {
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  loadbalancer_id     = "${azurerm_lb.lb1testweb.id}"
  name                = "ssh-running-probe"
  port                = 22
}

resource "azurerm_lb_rule" "lb1sftprule" {
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  loadbalancer_id     = "${azurerm_lb.lb1testweb.id}"
  name                           = "lb1sftprule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "lb1FEIpConfig"
  probe_id                       = "${azurerm_lb_probe.lb1testprobessh.id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.lb1testwebbepool.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "vm1bepool" {
    network_interface_id        = "${azurerm_network_interface.vm1nic1.id}"
    ip_configuration_name       = "vm1nicconfig1"
    backend_address_pool_id     = "${azurerm_lb_backend_address_pool.lb1testwebbepool.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "vm2bepool" {
    network_interface_id        = "${azurerm_network_interface.vm2nic1.id}"
    ip_configuration_name       = "vm2nicconfig1"
    backend_address_pool_id     = "${azurerm_lb_backend_address_pool.lb1testwebbepool.id}"
}

# Enables NAT
resource "azurerm_network_interface_nat_rule_association" "vm1natrule" {
  network_interface_id  = "${azurerm_network_interface.vm1nic1.id}"
  ip_configuration_name = "vm1nicconfig1"
  nat_rule_id           = "${azurerm_lb_nat_rule.lb1testnatrule.id}"
}