#!/bin/bash
#https://coder.com/docs/install/kubernetes/kubernetes-azure-app-gateway
#Deploy Coder on Azure with an Application Gateway
##Create Azure resource group:

# 015124-coder-gwc-dev-vnet
# 015124-coder-gwc-dev-subnet
# 015124-coder-gwc-dev-pls # private link service
# 015124-coder-gwc-dev-conn # 

location=germanywestcentral

resourcegroup=015124-coder-gwc-dev-rg

aksclustername=015124-coder-gwc-dev-aks
aksclusterrg=mc_${resourcegroup}_${aksclustername}_${location}

vmsize=Standard_D4ds_v5


set -x

# deploy coder

# Create a Private Link service using Azure CLI
# https://learn.microsoft.com/en-us/azure/private-link/create-private-link-service-cli

# az network vnet list --resource-group mc_${resourcegroup}_${aksclustername}_germanywestcentral -o tsv --query  "[].{Name:name}"
# aks-vnet-14029748
aksvnet=$(az network vnet list --resource-group mc_${resourcegroup}_${aksclustername}_germanywestcentral -o tsv --query  "[].{Name:name}")
az network vnet subnet update --name aks-subnet --vnet-name ${aksvnet} --resource-group mc_${resourcegroup}_${aksclustername}_germanywestcentral --disable-private-link-service-network-policies yes


frontendip=$(az network lb frontend-ip list --resource-group mc_${resourcegroup}_${aksclustername}_germanywestcentral --lb-name kubernetes-internal --query  "[].{Name:name}" -o tsv)
az network private-link-service create --resource-group mc_${resourcegroup}_${aksclustername}_germanywestcentral --name 015124-coder-gwc-dev-pls --vnet-name ${aksvnet} --subnet aks-subnet  --lb-name kubernetes-internal --lb-frontend-ip-configs $frontendip --location ${location}


az network vnet create --resource-group ${resourcegroup} --location ${location} --name 015124-coder-gwc-dev-vnet --address-prefixes 10.1.0.0/16 --subnet-name 015124-coder-gwc-dev-subnet --subnet-prefixes 10.1.0.0/24
export resourceid=$(az network private-link-service show --name 015124-coder-gwc-dev-pls --resource-group mc_${resourcegroup}_${aksclustername}_${location} --query id --output tsv)

az network private-endpoint create --connection-name 015124-coder-gwc-dev-conn --name 015124-coder-gwc-dev-pls --private-connection-resource-id $resourceid --resource-group ${resourcegroup} --subnet 015124-coder-gwc-dev-subnet --manual-request false --vnet-name 015124-coder-gwc-dev-vnet



echo az aks get-credentials --name ${aksclustername} --resource-group ${resourcegroup}
