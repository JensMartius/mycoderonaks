#!/bin/bash
#https://coder.com/docs/install/kubernetes/kubernetes-azure-app-gateway
#Deploy Coder on Azure with an Application Gateway
##Create Azure resource group:

# 015124-coder-gwc-dev-rg
# 015124-coder-gwc-dev-aks
# 015124-coder-gwc-dev-vnet
# 015124-coder-gwc-dev-ip
# 015124-coder-gwc-dev-subnet
# 015124-coder-gwc-dev-appgw

set -x


az group create --name 015124-coder-gwc-dev-rg --location germanywestcentral

##Create AKS cluster:

#az aks create --name 015124-coder-gwc-dev-aks --resource-group 015124-coder-gwc-dev-rg --network-plugin azure --enable-managed-identity --generate-ssh-keys
az aks create --name 015124-coder-gwc-dev-aks --resource-group 015124-coder-gwc-dev-rg --network-plugin azure --location germanywestcentral --node-vm-size Standard_D2s_v3 --enable-managed-identity --generate-ssh-keys
#az aks create --name 015124-coder-gwc-dev-aks --resource-group 015124-coder-gwc-dev-rg --network-plugin azure --location germanywestcentral --node-vm-size Standard_D4s_v3 --enable-managed-identity --generate-ssh-keys

##Create public IP:

az network public-ip create --name 015124-coder-gwc-dev-ip --resource-group 015124-coder-gwc-dev-rg --allocation-method Static --sku Standard

##Create VNet and subnet:

az network vnet create --name 015124-coder-gwc-dev-vnet --resource-group 015124-coder-gwc-dev-rg --address-prefix 10.0.0.0/16 --subnet-name 015124-coder-gwc-dev-subnet --subnet-prefix 10.0.0.0/24

##Create Azure application gateway, attach VNet, subnet and public IP:

az network application-gateway create --name 015124-coder-gwc-dev-appgw --resource-group 015124-coder-gwc-dev-rg --sku Standard_v2 --public-ip-address 015124-coder-gwc-dev-ip --vnet-name 015124-coder-gwc-dev-vnet --subnet 015124-coder-gwc-dev-subnet --priority 100

##Get app gateway ID:

appgwId=$(az network application-gateway show --name 015124-coder-gwc-dev-appgw --resource-group 015124-coder-gwc-dev-rg -o tsv --query "id")

##Enable app gateway ingress to AKS cluster:

az aks enable-addons --name 015124-coder-gwc-dev-aks --resource-group 015124-coder-gwc-dev-rg --addon ingress-appgw --appgw-id $appgwId

#exit 0

##Get AKS node resource group:

nodeResourceGroup=$(az aks show --name 015124-coder-gwc-dev-aks --resource-group 015124-coder-gwc-dev-rg -o tsv --query "nodeResourceGroup")

##Get AKS VNet name:

aksVnetName=$(az network vnet list --resource-group $nodeResourceGroup -o tsv --query "[0].name")

##Get AKS VNet ID:

aksVnetId=$(az network vnet show --name $aksVnetName --resource-group $nodeResourceGroup -o tsv --query "id")

##Peer VNet to AKS VNet:

az network vnet peering create --name AppGWtoAKSVnetPeering --resource-group 015124-coder-gwc-dev-rg --vnet-name 015124-coder-gwc-dev-vnet --remote-vnet $aksVnetId --allow-vnet-access

##Get app gateway VNet ID:

appGWVnetId=$(az network vnet show --name 015124-coder-gwc-dev-vnet --resource-group 015124-coder-gwc-dev-rg -o tsv --query "id")

##Peer AKS VNet to app gateway VNet:

az network vnet peering create --name AKStoAppGWVnetPeering --resource-group $nodeResourceGroup --vnet-name $aksVnetName --remote-vnet $appGWVnetId --allow-vnet-access

##Get AKS credentials:

az aks get-credentials --name 015124-coder-gwc-dev-aks --resource-group 015124-coder-gwc-dev-rg

# optional / tbd
# az aks enable-addons --name 015124-coder-gwc-dev-aks --resource-group 015124-coder-gwc-dev-rg --addon virtual-node --subnet-name 015124-coder-gwc-dev-subnet
