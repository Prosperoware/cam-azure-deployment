#!/bin/bash 
rg=devxherx12 #$1
vnetname=$(az network vnet list -g $rg --query "[].{Name:name}" -o tsv ) # $2
subnetName=Subnet1 
subnetback=Subnet1
echo Please wait we are getting the information of your Azure deployment

CosmosaccountName=$(az cosmosdb list -g $rg --query "[].{Name:name}" -o tsv)
mysqlServer=$(az mysql server list -g $rg --query "[].{Name:name}" -o tsv)
rule=camrule

echo Resource Group - $rg
echo vnetname - $vnetname
echo subnet - $subnetName
echo Cosmos Db - $CosmosaccountName
echo MySQL  - $mysqlServer

read -p'Press any key if all configurations are ok '
az network public-ip create --resource-group $rg --name NatPublicIP --version IPv4 --sku Standard 
publicIp=$(az network public-ip list --resource-group $rg --query "[].{ipAddress:ipAddress}" -o tsv)
echo Public ip created $publicIp

read -p'Public ip created, press any key to now configure the gateway '
az network nat gateway create --resource-group $rg --name PwNATgateway --public-ip-addresses  NatPublicIP --idle-timeout 10

read -p'Gateway created, press any key to now add GW to vnet '
az network vnet subnet update --resource-group $rg --vnet-name $vnetname --name $subnetName --nat-gateway PwNATgateway



svcEndpoint=$(az network vnet subnet show -g $rg -n $subnetback --vnet-name $vnetname --query 'id' -o tsv)
      
echo 'NAT Gateway configured'
echo $svcEndpoint

# # ###### START ----  COSMOS DB CONFIGURATIONS ######
# # ######################################################
read -p'Press any key to now configure cosmosdb network rules ' 
echo Setting isVirtualNetworkFilterEnabled to true!!
az cosmosdb update --name $CosmosaccountName -g $rg --enable-virtual-network true 

echo adding network rule!!
az cosmosdb network-rule add -n $CosmosaccountName -g $rg --virtual-network $vnetname --subnet $svcEndpoint  --ignore-missing-vnet-service-endpoint true


echo finished adding network rule!!
read -p'Press any key to now configure the subnet used for service endpoints for the cosmos db'

az network vnet subnet update -n $subnetback -g $rg --vnet-name $vnetname --service-endpoints Microsoft.AzureCosmosDB Microsoft.ServiceBus
echo finished configuring the subnet for service endpoints for cosmos db!!

# # ######################################################
# # ###### FINISH ----  COSMOS DB CONFIGURATIONS ######


read -p'Press any key to configure functions'

etl='etl-api'

az functionapp list --resource-group $rg --query "[].{Name:name}" -o tsv |
while read -r name; do
    echo "Processing function " $name 
    az functionapp config set --vnet-route-all-enabled false -g $rg -n $name 
    az functionapp config set -g $rg -n $name --ftps-state Disabled
    az functionapp update -g $rg -n $name --set httpsOnly=true
    az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'IP cam1' --action Allow --ip-address 3.9.236.119/32 --priority 100 
    az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'IP cam2' --action Allow --ip-address 18.130.49.85/32 --priority 100 
    az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'IP cam3' --action Allow --ip-address 18.205.167.41/32 --priority 100 
    az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'IP cam4' --action Allow --ip-address 34.198.68.230/32 --priority 100 
    az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'NatGWIp' --action Allow --ip-address $publicIp/32 --priority 100 
    
    if [[ $name == *"$etl"* ]]
    then
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph1' --action Allow --ip-address 52.159.23.209/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph2' --action Allow --ip-address 52.159.17.84/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph3' --action Allow --ip-address 52.147.213.251/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph4' --action Allow --ip-address 52.147.213.181/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph5' --action Allow --ip-address 13.85.192.59/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph6' --action Allow --ip-address 13.85.192.123/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph7' --action Allow --ip-address 13.89.108.233/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph8' --action Allow --ip-address 13.89.104.147/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph9' --action Allow --ip-address 20.96.21.67/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph10' --action Allow --ip-address 20.69.245.215/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph11' --action Allow --ip-address 137.135.11.161/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph12' --action Allow --ip-address 137.135.11.116/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph13' --action Allow --ip-address 52.159.107.50/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph14' --action Allow --ip-address 52.159.107.4/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph15' --action Allow --ip-address 52.229.38.131/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph16' --action Allow --ip-address 52.183.67.212/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph17' --action Allow --ip-address 52.142.114.29/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph18' --action Allow --ip-address 52.142.115.31/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph19' --action Allow --ip-address 51.124.75.43/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph20' --action Allow --ip-address 51.124.73.177/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph21' --action Allow --ip-address 20.44.210.83/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph22' --action Allow --ip-address 20.44.210.146/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph23' --action Allow --ip-address 40.80.232.177/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph24' --action Allow --ip-address 40.80.232.118/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph25' --action Allow --ip-address 20.48.12.75/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph26' --action Allow --ip-address 20.48.11.201/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph27' --action Allow --ip-address 104.215.13.23/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph28' --action Allow --ip-address 104.215.6.169/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph29' --action Allow --ip-address 52.148.24.136/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph30' --action Allow --ip-address 52.148.27.39/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph31' --action Allow --ip-address 40.76.162.99/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph32' --action Allow --ip-address 40.76.162.42/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph33' --action Allow --ip-address 40.74.203.28/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph34' --action Allow --ip-address 40.74.203.27/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph35' --action Allow --ip-address 13.86.37.15/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph36' --action Allow --ip-address 52.154.246.238/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph37' --action Allow --ip-address 20.96.21.98/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph38' --action Allow --ip-address 20.96.21.115/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph39' --action Allow --ip-address 137.135.11.222/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph40' --action Allow --ip-address 137.135.11.250/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph41' --action Allow --ip-address 52.159.109.205/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph42' --action Allow --ip-address 52.159.102.72/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph43' --action Allow --ip-address 52.151.30.78/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph44' --action Allow --ip-address 52.191.173.85/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph45' --action Allow --ip-address 51.104.159.213/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph46' --action Allow --ip-address 51.104.159.181/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph47' --action Allow --ip-address 51.138.90.7/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph48' --action Allow --ip-address 51.138.90.52/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph49' --action Allow --ip-address 52.148.115.48/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph50' --action Allow --ip-address 52.148.114.238/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph51' --action Allow --ip-address 40.80.233.14/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph52' --action Allow --ip-address 40.80.239.196/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph53' --action Allow --ip-address 20.48.14.35/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph54' --action Allow --ip-address 20.48.15.147/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph55' --action Allow --ip-address 104.215.18.55/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph56' --action Allow --ip-address 104.215.12.254/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph57' --action Allow --ip-address 20.199.102.157/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph58' --action Allow --ip-address 20.199.102.73/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph59' --action Allow --ip-address 13.87.81.123/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph60' --action Allow --ip-address 13.87.81.35/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph61' --action Allow --ip-address 20.111.9.46/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph62' --action Allow --ip-address 20.111.9.77/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph63' --action Allow --ip-address 13.87.81.133/32 --priority 100
        az functionapp config access-restriction add --resource-group $rg --name $name --rule-name 'graph64' --action Allow --ip-address 13.87.81.141/32 --priority 100
    fi


    az functionapp config set --vnet-route-all-enabled true -g $rg -n $name 
done



# mysql changes 
# enforce ssl https://docs.microsoft.com/en-us/azure/mysql/howto-configure-ssl
# echo internet access to cosmosdb disabled!!
# read -p'Press any key to enforce ssl on MySQL'
# az mysql server update --resource-group $rg --name $mysqlServer --ssl-enforcement Enabled

# echo finished enforcing ssl!
read -p'Press any key to configure vnet on MySQL'


#Configure Vnet service endpoints for Azure Database for MySQL

az network vnet subnet update --name $subnetback --resource-group $rg --vnet-name $vnetname --service-endpoints Microsoft.SQL Microsoft.AzureCosmosDB Microsoft.ServiceBus
az mysql server vnet-rule create --name $rule --resource-group $rg --server $mysqlServer --vnet-name $vnetname --subnet $subnetback


echo finished configuring vnet for MySQL!
# read -p'Press any key to disable public ip access to MySQL'
# az mysql server update --resource-group $rg --name $mysqlServer  --set publicNetworkAccess="Disabled"


# echo finished disabling public ip access to MySQL!
