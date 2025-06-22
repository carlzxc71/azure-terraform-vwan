terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "2.4.0"
    }
  }
}

provider "azapi" {
  enable_preflight = true
}

resource "azapi_resource" "rg" {
  type     = "Microsoft.Resources/resourceGroups@2025-04-01"
  name     = "rg-${var.environment}-${var.location_short}-vwan"
  location = var.location
}

resource "azapi_resource" "vwan_instance" {
  type      = "Microsoft.Network/virtualWans@2024-05-01"
  name      = "vwan-${var.environment}-${var.location_short}-vwan"
  parent_id = azapi_resource.rg.id
  location  = var.location
  body = {
    properties = {
      allowBranchToBranchTraffic = true
      disableVpnEncryption       = false
      allowVnetToVnetTraffic     = true
      type                       = "Standard"
    }
  }
}

resource "azapi_resource" "vwan_hub" {
  type      = "Microsoft.Network/virtualHubs@2024-05-01"
  name      = "vhub-${var.environment}-${var.location_short}-vwan"
  parent_id = azapi_resource.rg.id
  location  = var.location
  body = {
    properties = {
      addressPrefix        = "10.0.0.0/23"
      hubRoutingPreference = "VpnGateway"
      virtualRouterAutoScaleConfiguration = {
        minCapacity = 2
      }
      virtualWan = {
        id = azapi_resource.vwan_instance.id
      }
    }
  }
}

resource "azapi_resource" "spoke-vnet" {
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  name      = "vnet-${var.environment}-${var.location_short}-vwan"
  parent_id = azapi_resource.rg.id
  location  = var.location
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.2.0/24"]
      }
    }
  }
}

resource "azapi_resource" "subnet" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  name      = "sn-vwan-workload"
  parent_id = azapi_resource.spoke-vnet.id
  body = {
    properties = {
      addressPrefix = "10.0.2.0/24"
    }
  }
}

resource "azapi_resource" "spoke-vnet2" {
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
  name      = "vnet-${var.environment}-${var.location_short}-vwan2"
  parent_id = azapi_resource.rg.id
  location  = var.location
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.3.0/24"]
      }
    }
  }
}

resource "azapi_resource" "subnet2" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2024-05-01"
  name      = "sn-vwan-workload"
  parent_id = azapi_resource.spoke-vnet2.id
  body = {
    properties = {
      addressPrefix = "10.0.3.0/24"
    }
  }
}

resource "azapi_resource" "vhub-spoke-connectivity" {
  type      = "Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2024-05-01"
  parent_id = azapi_resource.vwan_hub.id
  name      = "vnet-connection-${azapi_resource.vwan_hub.name}-to-${azapi_resource.spoke-vnet.name}"
  body = {
    properties = {
      enableInternetSecurity = false
      remoteVirtualNetwork = {
        id = azapi_resource.spoke-vnet.id
      }
    }
  }
  schema_validation_enabled = false
}

resource "azapi_resource" "vhub-spoke-connectivity2" {
  type      = "Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2024-05-01"
  parent_id = azapi_resource.vwan_hub.id
  name      = "vnet-connection-${azapi_resource.vwan_hub.name}-to-${azapi_resource.spoke-vnet2.name}"
  body = {
    properties = {
      enableInternetSecurity = false
      remoteVirtualNetwork = {
        id = azapi_resource.spoke-vnet2.id
      }
    }
  }
  schema_validation_enabled = false
}
