/*
see this issue before implementing this reousrce
https://github.com/terraform-providers/terraform-provider-azurerm/issues/1576
*/
resource "azurerm_public_ip" "appgw1pip" {
  name                = "appgw1-pip"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  location            = "${var.location}"
  allocation_method   = "Dynamic"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name         = "be-addresspool"
  frontend_ip_configuration_name    = "feip-confg"
  backend_http_setting_name         = "be-htst"
  http_frontend_port_name           = "http-feport"
  https_frontend_port_name          = "https-feport"
  http_listener_name                = "http-listener"
  http_request_routing_rule_name    = "http-request-routing"
  https_listener_name               = "https-listener"
  https_request_routing_rule_name   = "https-request-routing"
}

resource "azurerm_application_gateway" "appgw1" {
  name                = "appgw1"
  resource_group_name = "${azurerm_resource_group.resourcegroup.name}"
  location            = "${var.location}"
  enable_http2        = true

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw1-ip-config"
    subnet_id = "${azurerm_subnet.appgw1subnetfe.id}"
  }

  frontend_port {
    name = "${local.http_frontend_port_name}"
    port = 80
  }

  frontend_port {
    name = "${local.https_frontend_port_name}"
    port = 443
  }

  ssl_certificate {
    name     = "fgcu2020wildcard"
    data     = "${base64encode(file("dummy.pfx"))}"
    password = "${var.ssl_certificate_password}"
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.appgw1pip.id}"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
  }

  backend_http_settings {
    name                  = "${local.backend_http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "${local.http_listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.http_frontend_port_name}"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "${local.https_listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.https_frontend_port_name}"
    protocol                       = "Https"
    ssl_certificate_name           = "wildcard-name"
  }

  request_routing_rule {
    name                       = "${local.https_request_routing_rule_name}"
    rule_type                  = "Basic"
    http_listener_name        = "${local.https_listener_name}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.backend_http_setting_name}"
  }

  probe {
    name                = "HttpsProbe"
    protocol            = "https"
    host                = "127.0.0.1"
    path                = "/"
    interval            = "30"
    timeout             = "120"
    unhealthy_threshold = "8"
  }
}