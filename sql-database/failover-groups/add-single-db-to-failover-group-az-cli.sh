#!/bin/bash
# Passed validation in Cloud Shell 12/01/2021

let "randomIdentifier=$RANDOM*$RANDOM"
location="East US"
resourceGroup="msdocs-azuresql-rg-$randomIdentifier"
tag="add-single-db-to-failover-group-az-cli"
server="msdocs-azuresql-server-$randomIdentifier"
database="msdocsazuresqldb$randomIdentifier"
login="msdocsAdminUser"
password="Pa$$w0rD-$randomIdentifier"
failoverGroup="msdocs-azuresql-failover-group-$randomIdentifier"
failoverLocation="Central US"
secondaryServer="msdocs-azuresql-secondary-server-$randomIdentifier"

echo "Using resource group $resourceGroup with login: $login, password: $password..."

echo "Creating $resourceGroup in $location..."
az group create --name $resourceGroup --location "$location" --tag $tag

echo "Creating $server in $location..."
az sql server create --name $server --resource-group $resourceGroup --location "$location"  --admin-user $login --admin-password $password

echo "Creating $database on $server..."
az sql db create --name $database --resource-group $resourceGroup --server $server --sample-name AdventureWorksLT

echo "Creating $secondaryServer in $failoverLocation..."
az sql server create --name $secondaryServer --resource-group $resourceGroup --location "$failoverLocation" --admin-user $login --admin-password $password

echo "Creating $failoverGroup between $server and $secondaryServer..."
az sql failover-group create --name $failoverGroup --partner-server $secondaryServer --resource-group $resourceGroup --server $server --failover-policy Automatic --grace-period 2 --add-db $database

echo "Confirming the role of each server in the failover group..." # note ReplicationRole property
az sql failover-group show --name $failoverGroup --resource-group $resourceGroup --server $server

echo "Failing over to $secondaryServer..."
az sql failover-group set-primary --name $failoverGroup --resource-group $resourceGroup --server $secondaryServer 

echo "Confirming role of $secondaryServer is now primary..." # note ReplicationRole property
az sql failover-group show --name $failoverGroup --resource-group $resourceGroup --server $server

echo "Failing back to $server...."
az sql failover-group set-primary --name $failoverGroup --resource-group $resourceGroup --server $server

# echo "Deleting all resources"
# az group delete --name $resourceGroup -y
