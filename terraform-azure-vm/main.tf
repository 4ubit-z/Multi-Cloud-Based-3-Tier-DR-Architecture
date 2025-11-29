terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.51.0"
    }
  }
  required_version = ">= 1.6.0"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "6692c162-4611-41d5-88d5-e8732f36579b"
}

variable "vm_count" {
  default = 3
}

# 1️⃣ Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "tf-rg-demo"
  location = "Korea Central"
}

# 2️⃣ Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "tf-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3️⃣ Private VM Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "tf-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.16/28"]
}

# 3-1️⃣ Bastion Subnet
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/27"]
}

# 4️⃣ NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "tf-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh-from-bastion"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "10.0.2.0/27"
    destination_address_prefix  = "*"
  }

  security_rule {
    name                       = "allow-rdp-from-bastion"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "3389"
    source_address_prefix       = "10.0.2.0/27"
    destination_address_prefix  = "*"
  }

  security_rule {
    name                       = "allow-all-from-bastion"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "10.0.2.0/27"
    destination_address_prefix  = "*"
  }
}

# 5️⃣ NIC
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "tf-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "tf-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.${20 + count.index}"
  }
}

# 6️⃣ NSG <-> NIC 연결
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 7️⃣ Private Linux VM (SSH Key + cloud-init UFW)
resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "tf-vm${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]

  # SSH Key 인증
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/ehgus/.ssh/id_rsa.pub")
  }

  disable_password_authentication = true

  os_disk {
    name                 = "tf-vm${count.index + 1}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # cloud-init UFW 설정
  custom_data = base64encode(<<EOF
#cloud-config
runcmd:
  - ufw default allow incoming
  - ufw allow from 10.0.2.0/27 to any port 22
  - ufw allow from 10.0.2.0/27 to any port 3389
  - ufw --force enable
EOF
  )
}

# 8️⃣ Bastion Public IP
resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 9️⃣ Bastion Host (Standard + Native Client)
resource "azurerm_bastion_host" "bastion" {
  name                = "tf-bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  ip_configuration {
    name                 = "bastion-ip"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

}

# 🔟 Outputs
output "vm_private_ips" {
  value = [for nic in azurerm_network_interface.nic : nic.ip_configuration[0].private_ip_address]
}

output "bastion_public_ip" {
  value = azurerm_public_ip.bastion_pip.ip_address
}
