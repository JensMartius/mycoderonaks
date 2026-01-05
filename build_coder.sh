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


az group create --name 015124-coder-gwc-dev-rg --location germanywestcentral

##Create AKS cluster:

az aks create --name 015124-coder-gwc-dev-aks --resource-group 015124-coder-gwc-dev-rg --network-plugin azure --enable-managed-identity --generate-ssh-keys
az aks create --name 015124-coder-gwc-dev-aks --resource-group 015124-coder-gwc-dev-rg --location germanywestcentral --node-vm-size Standard_D2s_v3 --enable-managed-identity --generate-ssh-keys

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

##Create Coder namespace:

kubectl create ns coder

##Deploy non-production PostgreSQL instance to AKS cluster:

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install coder-db bitnami/postgresql \
--set image.repository=bitnamilegacy/postgresql \
--namespace coder \
--set auth.username=coder \
--set auth.password=coder \
--set auth.database=coder \
--set persistence.size=10Gi

##Create the PostgreSQL secret:

kubectl create secret generic coder-db-url -n coder --from-literal=url="postgres://coder:coder@coder-db-postgresql.coder.svc.cluster.local:5432/coder?sslmode=disable"

##Deploy Coder to AKS cluster:

helm repo add coder-v2 https://helm.coder.com/v2
helm install coder coder-v2/coder \
    --namespace coder \
 --values values.yaml \
 --version 2.25.2

##Clean up Azure resources:

az group delete --name 015124-coder-gwc-dev-rg
az group delete --name MC_015124-coder-gwc-dev-rg_015124-coder-gwc-dev-aks_germanywestcentral
