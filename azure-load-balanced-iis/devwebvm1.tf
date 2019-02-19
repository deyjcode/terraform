# Configuration for Dev Web VM

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "devwebvmdiag" {
    name                        = "devwebvmdiag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.resourcegroup.name}"
    location                    = "${var.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "webtest"
    }
}

# Create public IP for devwebvm nic
resource "azurerm_public_ip" "devwebvmpip" {
    name                         = "devwebvmpip"
    location                     = "${var.location}"
    resource_group_name          = "${azurerm_resource_group.resourcegroup.name}"
    allocation_method            = "Static"
    tags {
        environment = "webtest"
    }
}

# Create network interface for devwebvm with devwebvmpip
resource "azurerm_network_interface" "devwebvmnic1" {
    name                      = "devwebvmnic1"
    location                  = "${var.location}"
    resource_group_name       = "${azurerm_resource_group.resourcegroup.name}"
    network_security_group_id = "${azurerm_network_security_group.webnsg.id}"

    ip_configuration {
        name                          = "devwebvmnicconfig1"
        subnet_id                     = "${azurerm_subnet.websub1.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.devwebvmpip.id}"
    }

    tags {
        environment = "webtest"
    }
}

resource "azurerm_virtual_machine" "devwebvm" {
    name                  = "devwebvm"
    location              = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.resourcegroup.name}"
    network_interface_ids = ["${azurerm_network_interface.devwebvmnic1.id}"]
    # Size SKUs are located at https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-general
    vm_size               = "Standard_F2s"

    storage_os_disk {
        name              = "devwebvmOsdisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "${var.osDiskType}"
    }

    delete_os_disk_on_termination = true

    license_type = "Windows_Server"

    # Use packer image from packer repository
    # This variable is located in vars.tf
    # Documentation: https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html#storage_image_reference
    storage_image_reference {
        id = "${data.azurerm_image.customimage.id}"
    }

    os_profile {
        computer_name  = "devwebvm"
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
        storage_uri = "${azurerm_storage_account.devwebvmdiag.primary_blob_endpoint}"
    }

    tags {
        environment = "webtest"
    }
}

# Run Post-Creation Script to allow Ansible communication (WinRM)
resource "azurerm_virtual_machine_extension" "devwebvmansible" {
    name            = "devwebvmansible"
    location        = "${var.location}"
    resource_group_name   = "${azurerm_resource_group.resourcegroup.name}"
    virtual_machine_name    = "${azurerm_virtual_machine.devwebvm.name}"
    # Run az vm extension image list --location eastus -o table to determine below values
    # Use CustomScriptExtension for Windows and the Publisher is Microsoft.Compute
    # Use CustomScript for Linux and Publisher Microsoft.Azure.Extensions
    publisher       = "Microsoft.Compute"
    type            = "CustomScriptExtension"
    type_handler_version    = "1.9"
    depends_on      = ["azurerm_virtual_machine.devwebvm"]
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