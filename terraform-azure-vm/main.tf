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

# VM 개수 정의 (필요시 조정)
variable "vm_count" {
  default = 3
}

# 1️⃣ 리소스 그룹
resource "azurerm_resource_group" "rg" {
  name     = "tf-rg-demo"
  location = "Korea Central"
}

# 2️⃣ 가상 네트워크
resource "azurerm_virtual_network" "vnet" {
  name                = "tf-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 3️⃣ 서브넷 (10.0.1.16/28 → 10.0.1.16 ~ 10.0.1.31)
resource "azurerm_subnet" "subnet" {
  name                 = "tf-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.16/28"]
}

# 4️⃣ 공용 IP (VM마다 하나씩 생성)
resource "azurerm_public_ip" "public_ip" {
  count               = var.vm_count
  name                = "tf-public-ip-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5️⃣ NSG (SSH 허용)
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
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
}

# 6️⃣ NIC (각 VM에 고유 사설 IP)
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "tf-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "tf-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.${20 + count.index}"  # 10.0.1.20~22 (3대)
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
  }
}

# 7️⃣ NSG - NIC 연결
resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 8️⃣ VM 생성
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

# 9️⃣ 출력 (각 VM의 공인 IP 및 사설 IP 목록)
output "vm_public_ips" {
  description = "생성된 VM들의 공인 IP 목록"
  value       = azurerm_public_ip.public_ip[*].ip_address
}

output "vm_private_ips" {
  description = "생성된 VM들의 사설 IP 목록"
  value       = [for nic in azurerm_network_interface.nic : nic.ip_configuration[0].private_ip_address]
}

