# Azure Load Balanced IIS

## Requirements

The only requirements are:

* `Terraform`

Take a look at the `vars.tf` file for which values are required.

This folder will build out an infrastructure which utilizes the following:

* One Resource Group
* Three virtual machines using the `2016core` sku.
    * One by itself
    * Two in an Availability Set
* One Layer 7 Load Balancer (Application Gateway)
* One Layer 4 Load Balancer (Load Balancer)
    * NAT Rule for RDP and SFTP
* One Virtual Network
    * Three Subnets
* One Network Security Group

All three virtual machines will be enabled for Ansible remoting. [See here for details](https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html).

## Dummy.pfx

The repository uses an empty `dummy.pfx` file to simulate an actual `.pfx` file. Obviously, replace this file with your own `pfx` file to be used. As well, it is recommended to use a vault of some kind for passwords - such as the `pfx` file password.