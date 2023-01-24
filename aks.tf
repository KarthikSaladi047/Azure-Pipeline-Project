terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.40.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
}

//creating Azure Kubernetes service
resource "azurerm_resource_group" "aks" {
  name     = "my-aks-rg"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "my-aks-cluster"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "my-aks-cluster"

  kubernetes_version = "1.19.7"

  role_based_access_control {
    enabled = true
  }
}

// creating Azure container registry
resource "azurerm_resource_group" "container_rg" {
  name     = "acr-rg"
  location = "East US"
}

resource "azurerm_container_registry" "acr" {
  name                = "my-registry"
  resource_group_name = azurerm_resource_group.container_rg.name
  location            = azurerm_resource_group.container_rg.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location                = "West Europe"
    zone_redundancy_enabled = true
    tags                    = {}
  }
  georeplications {
    location                = "North Europe"
    zone_redundancy_enabled = true
    tags                    = {}
  }
}