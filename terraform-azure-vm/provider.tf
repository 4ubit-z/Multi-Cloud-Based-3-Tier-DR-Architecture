# provider.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.8.0"
}

provider "azurerm" {
  features {}

  subscription_id = "6692c162-4611-41d5-88d5-e8732f36579b"  # ✅ 방금 선택한 구독 ID
}
