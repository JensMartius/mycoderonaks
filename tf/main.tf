resource "azurerm_resource_group" "res-0" {
  location = "germanywestcentral"
  name     = "015124-coder-gwc-dev-rg"
}
resource "azurerm_kubernetes_cluster" "res-1" {
  dns_prefix          = "a015124-co-015124-coder-gwc-6f81ef"
  location            = "germanywestcentral"
  name                = "015124-coder-gwc-dev-aks"
  resource_group_name = "015124-coder-gwc-dev-rg"
  default_node_pool {
    name = "nodepool1"
    upgrade_settings {
      max_surge = "10%"
    }
  }
  identity {
    type = "SystemAssigned"
  }
  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.res-3.id
  }
  linux_profile {
    admin_username = "azureuser"
    ssh_key {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1q5O6SQ9vARzZeoaGGEyjbqbCXtqPs5rnJUFDNrM4Bwri4Hf7F3rHGhRu96av8luE/OQLOC7wyc5QElLypu7pMWdDEV3E6rXo+LjZs+QRzmQjg6HX2B6BCpzPsNS74SBU5O+fkDBN5hzRYe+EdlEQyCGxim5vTWjnzwpLPqxW7CzunHFb6BELPzfOiNPBonM3EWl7eAlseP4RBaNPt5b0YuutdV5z6pykuZPfUoYwPLjvEyyv5nLFGA65M38dvISiN6yr9jWp98/1u4tGbORQkzYUJ8b8M3kq/o1O+kcav2egpanZtgw4HlsKSi7c07ITN3pDTSgRgqG0FrRhrsf226NwcoSPyLvLCIalzqa1GpHrwk3Bb7aqJ66gbZxtRzX3kf0J58xbm1zKHqHFXg0cv88loaRXE717WUSKdWLu3LosDvqOxmIGuqDNySorHs3B43VI6SVksbyJzWL3pyoiJuSo0q/AhHZwhXqDHEa+lDO28HR/KUQF90waZCBFGJ8= jens@mysurface\n"
    }
  }
}
resource "azurerm_kubernetes_cluster_node_pool" "res-2" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.res-1.id
  mode                  = "System"
  name                  = "nodepool1"
  workload_runtime      = "OCIContainer"
  upgrade_settings {
    max_surge = "10%"
  }
}
resource "azurerm_application_gateway" "res-3" {
  location            = "germanywestcentral"
  name                = "015124-coder-gwc-dev-appgw"
  resource_group_name = "015124-coder-gwc-dev-rg"
  tags = {
    ingress-for-aks-cluster-id = "/subscriptions/6f81ef09-202c-4e6b-9f7c-1fff436c0fbf/resourcegroups/015124-coder-gwc-dev-rg/providers/Microsoft.ContainerService/managedClusters/015124-coder-gwc-dev-aks"
    managed-by-k8s-ingress     = "1.8.1/05a0d9c7/2025-04-04-14:12T-0700"
  }
  backend_address_pool {
    name = "defaultaddresspool"
  }
  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "defaulthttpsetting"
    port                  = 80
    probe_name            = "defaultprobe-Http"
    protocol              = "Http"
  }
  frontend_ip_configuration {
    name                 = "appGatewayFrontendIP"
    public_ip_address_id = azurerm_public_ip.res-4.id
  }
  frontend_port {
    name = "appGatewayFrontendPort"
    port = 80
  }
  gateway_ip_configuration {
    name      = "appGatewayFrontendIP"
    subnet_id = azurerm_subnet.res-6.id
  }
  http_listener {
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name             = "appGatewayFrontendPort"
    name                           = "fl-452c578b4f742bd7a3927c3caf2b604e"
    protocol                       = "Http"
  }
  probe {
    host                = "localhost"
    interval            = 30
    name                = "defaultprobe-Http"
    path                = "/"
    protocol            = "Http"
    timeout             = 30
    unhealthy_threshold = 3
    match {
      status_code = ["200-399"]
    }
  }
  request_routing_rule {
    backend_address_pool_name  = "defaultaddresspool"
    backend_http_settings_name = "defaulthttpsetting"
    http_listener_name         = "fl-452c578b4f742bd7a3927c3caf2b604e"
    name                       = "rr-452c578b4f742bd7a3927c3caf2b604e"
    priority                   = 19500
    rule_type                  = "Basic"
  }
  sku {
    capacity = 2
    name     = "Standard_v2"
    tier     = "Standard_v2"
  }
}
resource "azurerm_public_ip" "res-4" {
  allocation_method   = "Static"
  location            = "germanywestcentral"
  name                = "015124-coder-gwc-dev-ip"
  resource_group_name = "015124-coder-gwc-dev-rg"
  depends_on = [
    azurerm_resource_group.res-0
  ]
}
resource "azurerm_virtual_network" "res-5" {
  address_space       = ["10.0.0.0/16"]
  location            = "germanywestcentral"
  name                = "015124-coder-gwc-dev-vnet"
  resource_group_name = "015124-coder-gwc-dev-rg"
  depends_on = [
    azurerm_resource_group.res-0
  ]
}
resource "azurerm_subnet" "res-6" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "015124-coder-gwc-dev-subnet"
  resource_group_name  = "015124-coder-gwc-dev-rg"
  virtual_network_name = "015124-coder-gwc-dev-vnet"
  depends_on = [
    azurerm_virtual_network.res-5
  ]
}
resource "azurerm_virtual_network_peering" "res-7" {
  name                      = "AppGWtoAKSVnetPeering"
  remote_virtual_network_id = "/subscriptions/6f81ef09-202c-4e6b-9f7c-1fff436c0fbf/resourceGroups/MC_015124-coder-gwc-dev-rg_015124-coder-gwc-dev-aks_germanywestcentral/providers/Microsoft.Network/virtualNetworks/aks-vnet-14029748"
  resource_group_name       = "015124-coder-gwc-dev-rg"
  virtual_network_name      = "015124-coder-gwc-dev-vnet"
  depends_on = [
    azurerm_virtual_network.res-5
  ]
}
