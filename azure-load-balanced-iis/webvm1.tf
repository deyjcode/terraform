# Configuration for Web VM 1

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "webvm1diag" {
    name                        = "webvm1diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.resourcegroup.name}"
    location                    = "${var.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "webtest"
    }
}

# Uncomment this resource to apply public IP
resource "azurerm_public_ip" "webvm1pip" {
    name                         = "webvm1pip"
    location                     = "${var.location}"
    resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
    allocation_method            = "Static"
    tags {
        environment = "webtest"
    }
}

# Create network interface for vm1
resource "azurerm_network_interface" "vm1nic1" {
    name                      = "vm1nic1"
    location                  = "${var.location}"
    resource_group_name       = "${azurerm_resource_group.resourcegroup.name}"
    network_security_group_id = "${azurerm_network_security_group.webnsg.id}"

    ip_configuration {
        name                          = "vm1nicconfig1"
        subnet_id                     = "${azurerm_subnet.websub1.id}"
        private_ip_address_allocation = "dynamic"
        # Uncomment this resource to apply public IP
        public_ip_address_id          = "${azurerm_public_ip.webvm1pip.id}"
    }

    tags {
        environment = "webtest"
    }
}

resource "azurerm_virtual_machine" "webvm1" {
    name                  = "webvm1"
    location              = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.resourcegroup.name}"
    network_interface_ids = ["${azurerm_network_interface.vm1nic1.id}"]
    # Size SKUs are located at https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general
    vm_size               = "Standard_F2s"

    storage_os_disk {
        name              = "webvm1Osdisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "${var.osDiskType}"
    }

    delete_os_disk_on_termination = true

    license_type = "Windows_Server"

    /* 
    Use packer image from packer repository
    This variable is located in vars.tf
    Documentation: https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html#storage_image_reference
    */
    storage_image_reference {
        id = "${data.azurerm_image.customimage.id}"
    }

    os_profile {
        computer_name  = "webvm1"
        admin_username = "${var.admin_username}"
        # Uncomment next line to enable variable prompt at runtime
        admin_password = "${var.admin_password}"
    }

    os_profile_windows_config {
        # We must provision vm agent to deploy extension
        provision_vm_agent = true
        # Research more information on https https://support.microsoft.com/en-us/help/2019527/how-to-configure-winrm-for-https
        winrm {
            protocol = "http"
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.webvm1diag.primary_blob_endpoint}"
    }

    tags {
        environment = "webtest"
    }

    # Add the system to an availability set
    availability_set_id =        "${azurerm_availability_set.webtestavail1.id}"
}

# Run Post-Creation Script to allow Ansible communication (WinRM)
resource "azurerm_virtual_machine_extension" "webvm1ansibleremote" {
    name            = "vm1ansibleremote"
    location        = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.resourcegroup.name}"
    virtual_machine_name    = "${azurerm_virtual_machine.webvm1.name}"
    # Run az vm extension image list --location eastus -o table to determine below values
    # Use CustomScriptExtension for Windows and the Publisher is Microsoft.Compute
    # Use CustomScript for Linux and Publisher Microsoft.Azure.Extensions
    publisher       = "Microsoft.Compute"
    type            = "CustomScriptExtension"
    type_handler_version    = "1.9"
    depends_on      = ["azurerm_virtual_machine.webvm1"]
    settings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"]
    }
    SETTINGS
    protected_settings = <<PROTECTED_SETTINGS
    {
        "commandToExecute": "powershell.exe -executionpolicy Unrestricted -file ./ConfigureRemotingForAnsible.ps1 -ForceNewSSLCert"
    }
    PROTECTED_SETTINGS
    tags {
        environment = "webtest"
    }
}

/* 
Adds Virtual Machine to Backend Address Pool for Gateway
We need to add the virtual machine's NIC card for this association.
*/
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "webvm1appgw1" {
  network_interface_id    = "${azurerm_network_interface.vm1nic1.id}"
  ip_configuration_name   = "${azurerm_network_interface.vm1nic1.ip_configuration.0.name}"
  backend_address_pool_id = "${azurerm_application_gateway.appgw1.backend_address_pool.0.id}"
}