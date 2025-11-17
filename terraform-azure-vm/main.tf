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
  features {}
  subscription_id = "6692c162-4611-41d5-88d5-e8732f36579b"
}

variable "vm_count" {
  default = 3
}

###########################################
# 1️⃣ 리소스 그룹
###########################################
resource "azurerm_resource_group" "rg" {
  name     = "tf-rg-demo"
  location = "Korea Central"
}

###########################################
# 2️⃣ 가상 네트워크
###########################################
resource "azurerm_virtual_network" "vnet" {
  name                = "tf-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

###########################################
# 3️⃣ 서브넷 (Private VM용)
###########################################
resource "azurerm_subnet" "subnet" {
  name                 = "tf-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.16/28"]
}

###########################################
# 3-1️⃣ Bastion 전용 Subnet
###########################################
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/27"]
}

###########################################
# 4️⃣ Private VM용 NSG (SSH 허용)
###########################################
resource "azurerm_network_security_group" "nsg" {
  name                = "tf-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "0-65535"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

###########################################
# 5️⃣ Private VM NIC (Public IP 없음)
###########################################
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "tf-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "tf-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.${20 + count.index}"  # 10.0.1.20~22
  }
}

###########################################
# 6️⃣ NSG - Private VM 연결
###########################################
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

###########################################
# 7️⃣ Private VM 생성
###########################################
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

  admin_password = "Password1234!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

###########################################
# 8️⃣ Bastion용 Public IP
###########################################
resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

###########################################
# 9️⃣ Bastion Host
###########################################
resource "azurerm_bastion_host" "bastion" {
  name                = "tf-bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                 = "bastion-ip"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

###########################################
# 🔥 JumpBox 추가 (SSH Proxy/Jumphost)
###########################################
resource "azurerm_public_ip" "jumpbox_pip" {
  name                = "jumpbox-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "jumpbox-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "jumpbox-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumpbox_pip.id
  }
}

resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                = "jumpbox-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "0-65535"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jumpbox_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id = azurerm_network_security_group.jumpbox_nsg.id
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "jumpbox"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.jumpbox_nic.id
  ]

  admin_password = "Password1234!"
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

###########################################
# 10️⃣ 출력
###########################################
output "vm_private_ips" {
  description = "생성된 VM들의 사설 IP 목록"
  value       = [for nic in azurerm_network_interface.nic : nic.ip_configuration[0].private_ip_address]
}

output "bastion_public_ip" {
  description = "Bastion Host Public IP"
  value       = azurerm_public_ip.bastion_pip.ip_address
}

output "jumpbox_public_ip" {
  description = "JumpBox Public IP"
  value       = azurerm_public_ip.jumpbox_pip.ip_address
}
