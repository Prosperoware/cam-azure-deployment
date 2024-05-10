#!/bin/bash
#az login
#az account set in case of multiple account , set any one subscription

branch=master
echo -e "Default branch is $branch.\n"

azureAccount=$(az account show)
# name=$(echo "$azureAccount" | grep -o '"name": *"[^"]*"' | awk -F'"' '{print $4}'| head -n 1)
# echo $name

if [ -n "$azureAccount" ]; then
    echo "You are logged in."
else
    echo "You are not logged in, Redirecting you to do az login."
    az login
    azureAccount=$(az account show)
    if [ -n "$azureAccount" ]; then
        echo -e "\n"
        echo  "You are logged in."
    else
        echo "Please try again."
        exit 1
     fi
fi

# extract_field() {
#     local field_name=$1
#     local json_response=$2
#     local field_value=$(echo "$azureAccount" | tr -d '{}' | tr ',' '\n' | grep "\"$field_name\"" | cut -d ':' -f 2 | tr -d '"' | sed 's/^ *//')
#     echo "$field_value"
#  }

# user_name=$(extract_field "name" "$(extract_field "user" "$azureAccount")")

# word1=$(echo "$user_name" | awk -F ' ' '{print $1}')
# word2=$(echo "$user_name" | awk -F ' ' '{print $2}')

# echo -e "Hello, You are logged in into $name subscription. \n"
echo -e "\n"
echo "Please enter the resource group."
read resourceGroup
echo -e "Please wait..."

response=$(az group show --name $resourceGroup)
resourceGroupRes=$(echo "$response" | grep -o '"name": *"[^"]*"' | awk -F'"' '{print $4}')

if [ "$resourceGroupRes" = "$resourceGroup" ]; then
    echo -e "Resource group found.\n\n"
else 
   echo "Resource group does not exists."
   exit 1
fi

echo -e "Please select a Feature: \n"
echo "1. Press 1 for ETL:"
echo -e "2. Press 2 for Content Sync: \n"
read choice

# Perform action based on user input
case $choice in
    1)
        echo "Performing Action for ETL:"

        echo -e "Please enter correct function app name for etl-api. \n\n"
        read etlApi
        echo "Please wait..."

        if az functionapp show --name $etlApi --resource-group $resourceGroup &> /dev/null; then
           echo "Functon App $etlApi exists in resource group $resourceGroup"
           echo -e "etl-api.zip will be deployed into $etlApi function app.\n"
        else
            echo "Functon App $etlApi does not exists in resource group $resourceGroup"
            exit 1
        fi

        echo -e "Please enter function app name for etl-action. \n\n"
        read etlAction
        echo "Please wait..."
        if az functionapp show --name $etlAction --resource-group $resourceGroup &> /dev/null; then
           echo "Functon App $etlAction exists in resource group $resourceGroup"
           echo -e "etl-api.zip will be deployed into $etlAction function app.\n"
        else
            echo "Functon App $etlAction does not exists in resource group $resourceGroup"
            exit 1
        fi

        echo -e "Please enter function app name for etl-mapping. \n\n"
        read etlMapping
        echo "Please wait..."
        if az functionapp show --name $etlMapping --resource-group $resourceGroup &> /dev/null; then
           echo "Functon App $etlMapping exists in resource group $resourceGroup"
           echo -e "etl-api.zip will be deployed into $etlMapping function app.\n"
        else
            echo "Functon App $etlMapping does not exists in resource group $resourceGroup"
            exit 1
        fi
        echo -e "Please enter function app name for etl-office-audit. \n\n"
        read etlOfficeAudit
        echo "Please wait..."
        if az functionapp show --name $etlOfficeAudit --resource-group $resourceGroup &> /dev/null; then
           echo "Functon App $etlOfficeAudit exists in resource group $resourceGroup"
           echo -e "etl-api.zip will be deployed into $etlOfficeAudit function app.\n"
        else
            echo "Functon App $etlOfficeAudit does not exists in resource group $resourceGroup"
            exit 1
        fi
        echo -e "Please enter function app name for etl-process. \n\n"
        read etlProcess
        echo "Please wait..."
        if az functionapp show --name $etlProcess --resource-group $resourceGroup &> /dev/null; then
           echo "Functon App $etlProcess exists in resource group $resourceGroup"
           echo -e "etl-api.zip will be deployed into $etlProcess function app.\n"
        else
            echo "Functon App $etlProcess does not exists in resource group $resourceGroup"
            exit 1
        fi
        echo -e "Please enter function app name for etl-renewal. \n\n"
        read etlRenewal
        echo "Please wait..."
        if az functionapp show --name $etlRenewal --resource-group $resourceGroup &> /dev/null; then
           echo "Functon App $etlRenewal exists in resource group $resourceGroup"
           echo -e "etl-api.zip will be deployed into $etlRenewal function app.\n"
        else
            echo "Functon App $etlRenewal does not exists in resource group $resourceGroup"
            exit 1
        fi

        echo -e "\n\n"
        echo -e "Downloading etl-api.zip file."
        ear=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-api.zip?ref=$branch)
        eardul=$(echo "$ear" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        curl -o etl-api.zip $eardul

        echo -e "\n\n"
        echo -e "Downloading etl-action.zip file."
        eacr=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-action.zip?ref=$branch)
        eacrdul=$(echo "$eacr" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        curl -o etl-action.zip $eacrdul

        # echo "Downloading etl-config.zip file."
        # ecr=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-config.zip?ref=$branch)
        # ecrdul=$(echo "$ecr" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        # curl -o etl-config.zip $ecrdul

        echo -e "\n\n"
        echo -e "Downloading etl-mapping.zip file."
        emr=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-mapping.zip?ref=$branch)
        emrdul=$(echo "$emr" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        curl -o etl-mapping.zip $emrdul

        echo -e "\n\n"
        echo -e "Downloading etl-office-audit.zip file."
        eoar=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-office-audit.zip?ref=$branch)
        eoardul=$(echo "$eoar" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        curl -o etl-office-audit.zip $eoardul

        echo -e "\n\n"
        echo -e "Downloading etl-process.zip file."
        epr=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-process.zip?ref=$branch)
        eprdul=$(echo "$epr" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        curl -o etl-process.zip $eprdul

        echo -e "\n\n"
        echo "Downloading etl-renewal.zip file."
        epr=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-renewal.zip?ref=$branch)
        eprdul=$(echo "$epr" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        curl -o etl-renewal.zip $eprdul

        echo -e "\n\n"
        echo -e "Deployment started. \n\n"
        az webapp deploy --resource-group $resourceGroup --name $etlApi --src-path etl-api.zip --type zip --async false
        az webapp deploy --resource-group $resourceGroup --name $etlAction --src-path etl-action.zip --type zip --async false
        az webapp deploy --resource-group $resourceGroup --name $etlMapping --src-path etl-mapping.zip --type zip --async false
        az webapp deploy --resource-group $resourceGroup --name $etlOfficeAudit --src-path etl-office-audit.zip --type zip --async false
        az webapp deploy --resource-group $resourceGroup --name $etlProcess --src-path etl-process.zip --type zip --async false
        az webapp deploy --resource-group $resourceGroup --name $etlRenewal --src-path etl-renewal.zip --type zip --async false
        echo -e "Deployment completed."
        echo "Script ended."

        ;;
    2)
        echo -e "Performing Action for ContentSync:"

        echo -e "Please enter correct function app name for contentsync-api."
        read contentSyncApi
        echo "Please wait..."

        if az functionapp show --name $contentSyncApi --resource-group $resourceGroup &> /dev/null; then
           echo "Functon App $contentSyncApi exists in resource group $resourceGroup"
           echo -e "contentsync-api.zip will be deployed into $contentSyncApi function app. \n\n"
        else
            echo "Functon App $contentSyncApi does not exists in resource group $resourceGroup"
            exit 1
        fi

        echo -e "Please enter correct function app name for contentsync-process."
        read contentSyncProcess
        echo "Please wait..."
        if az functionapp show --name $contentSyncProcess --resource-group $resourceGroup &> /dev/null; then
           echo "Functon App $contentSyncProcess exists in resource group $resourceGroup"
           echo -e "contentsync-process.zip will be deployed into $contentSyncProcess function app. \n\n"
        else
            echo "Functon App $contentSyncProcess does not exists in resource group $resourceGroup"
            exit 1
        fi

        echo -e "Please enter correct function app name for contentsync-retry."
        read contentSyncRetry
        echo "Please wait..."

        if az functionapp show --name $contentSyncRetry --resource-group $resourceGroup &> /dev/null; then
           echo "Functon App $contentSyncRetry exists in resource group $resourceGroup"
           echo -e "contentsync-retry.zip will be deployed into $contentSyncApi function app. \n\n"
        else
            echo "Functon App $contentSyncRetry does not exists in resource group $resourceGroup"
            exit 1
        fi

        echo -e "\n\n"
        echo -e "Downloading contentsync.api.zip file."
        csar=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/contentsync-api.zip?ref=$branch)
        csardul=$(echo "$csar" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        curl -o contentsync-api.zip $csardul
 
        echo -e "\n\n"
        echo -e "Downloading contentsync-process.zip file."
        cspr=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/contentsync-process.zip?ref=$branch)
        csprdul=$(echo "$cspr" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        curl -o contentsync-process.zip $csprdul
        
        echo -e "\n\n"
        echo -e "Downloading contentsync-retry.zip file."
        csrr=$(curl -s https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/contentsync-retry.zip?ref=$branch)
        csrrdul=$(echo "$csrr" | grep -o '"download_url": *"[^"]*"' | awk -F'"' '{print $4}')
        curl -o contentsync-retry.zip $csrrdul

        echo -e "\n\n"
        echo -e "Deployment started. \n\n"
        az webapp deploy --resource-group $resourceGroup --name $contentSyncApi --src-path contentsync-api.zip --type zip --async false
        az webapp deploy --resource-group $resourceGroup --name $contentSyncProcess --src-path contentsync-process.zip --type zip --async false
        az webapp deploy --resource-group $resourceGroup --name $contentSyncRetry --src-path contentsync-retry.zip --type zip --async false
        echo -e "Deployment completed."
        echo "Script ended."
        ;;
    *)
        echo "Invalid choice. Please enter a number either 1 or 2."
        ;;
esac