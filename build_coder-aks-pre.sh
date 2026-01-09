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

# az group delete --name ${resourcegroup}

az group create --name ${resourcegroup} --location ${location}

##Create AKS cluster:
az aks create --name ${aksclustername} --resource-group ${resourcegroup} --network-plugin azure --location ${location} --node-vm-size ${vmsize} --enable-managed-identity --generate-ssh-keys 
if [ $? -ne 0 ]; then
  exit 1
fi

# deploy coder


echo az aks get-credentials --name ${aksclustername} --resource-group ${resourcegroup}
