$logFilePath = "ps-script-log.txt"
function Log-Message {
    param(
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFilePath -Append
}

if(Test-Path $logFilePath){
    Clear-Content -Path $logFilePath
    Write-Host "Old log deleted."
}else{
    Write-Host "Log file not found , Creating $logFilePath"
}

Log-Message "------------------Starting script execution------------------------------------"

$branch = "master"
Log-Message "Selected branch $branch"

$maxRetries = 3
$retryCount = 0

do {
    $azureAccount = az account show | ConvertFrom-Json
    $retryCount++

    if (-not $azureAccount) {
        Log-Message "User is not logged in. Initiating az login for $retryCount time."
        Write-Host "Login attempt $retryCount."
        az login
    }
} while (-not $azureAccount -and $retryCount -lt $maxRetries)

if ($azureAccount) {
    Log-Message "User is logged in. $azureAccount"
    Write-Host "You are logged in."
}
else {
    Log-Message "Login failed after $maxRetries attempts. Exiting..."
    Write-Host "Login failed after $maxRetries attempts. Exiting..."
    exit 1
}


$maxRetries = 3
$retryCount = 0

do {
    Log-Message "Taking input from user for resource"
    $resourceGroup = Read-Host "Please enter the resource group"
    Write-Host "Please wait..."


    $response = az group show --name $resourceGroup | ConvertFrom-Json
    $resourceGroupRes = $response.name
    Log-Message "User entered resource group $resourceGroup , az group show response:  $response"
    if ($resourceGroupRes -eq $resourceGroup) {
        Log-Message "Resource group found"
        Write-Host "Resource group found.`n"
        break
    }
    else {
        Log-Message "Resource group '$resourceGroup' does not exist. Retrying...`n"
        Write-Host "Resource group '$resourceGroup' does not exist. Retrying...`n"
        $retryCount++
    }
} while ($retryCount -lt $maxRetries)

if ($retryCount -ge $maxRetries) {
    Log-Message "Failed to find the resource group after $maxRetries attempts. Exiting..."
    Write-Host "Failed to find the resource group after $maxRetries attempts. Exiting..."
    exit 1
}

$count = 0
$functionNames = az functionapp list --resource-group $resourceGroup --query "[].name"
# $functionNames = az functionapp list --resource-group $resourceGroup --query "[].{name:name, id:id}" --orderby name -o json

# functionAppList=$(az functionapp list --resource-group rg --query "[].{Name:name, CreatedTime:properties.createdTime, LastModifiedTime:properties.lastModifiedTime}" --output json)
# functionNames=$(echo "$functionAppList" | jq -r 'max_by(.CreatedTime, .LastModifiedTime).Name')

Log-Message "Functon app names: $functionNames"
if(!$functionNames){
    Log-Message "Function app not found."
    Write-Host "Function app not found."
    exit 1
}

foreach ($functionName in $functionNames.Split("`n")) {
    Log-Message $functionName

        if ($functionName -like "*etl-api*") { $etlAPI = $functionName }
        if ($functionName -like "*etl-action*") { $etlAction = $functionName }
        if ($functionName -like "*etl-renewal*") { $etlRenewal = $functionName }
        if ($functionName -like "*etl-mapping*") { $etlMapping = $functionName }
        if ($functionName -like "*etl-office-audit*") { $etlAudit = $functionName }
        if ($functionName -like "*etl-process*") { $etlProcess = $functionName }
        if ($functionName -like "*contentsync-api*") { $contentsyncAPI = $functionName }
        if ($functionName -like "*contentsync-process*") { $contentsyncProcess = $functionName }
        if ($functionName -like "*contentsync-retry*") { $contentsyncRetry = $functionName }

        $count++
}
if ($count -le 0) {
    Write-Host "Function app not found."
    exit 1
}
Write-Host "Total $count function app found. `n"
Write-Host "ContentSync function app names are..."
Write-Host $contentsyncAPI
Write-Host $contentsyncProcess
Write-Host $contentsyncRetry
Write-Host "`n"
Write-Host "ETL function app names are..."
Write-Host $etlAPI
Write-Host $etlAction
Write-Host $etlRenewal
Write-Host $etlMapping
Write-Host $etlAudit
Write-Host $etlProcess

Write-Host "`n"
Write-Host "Zip files will be updated in these functions Apps."

if ($etlAPI) {
    Write-Host "`n"
    Write-Host "Downloading etl-api.zip file."
    Log-Message "Downloading etl-api.zip file"
    Write-Host "Please wait..."
    try {
        $ear = Invoke-RestMethod -Uri "https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-api.zip?ref=$branch"
        $eardul = $ear.download_url
        Log-Message "Download Url $eardul."
        Invoke-WebRequest -Uri $eardul -OutFile "etl-api.zip"
        Write-Host "Downloading completed."
        Log-Message "Downloading completed. `n"

    }
    catch {
        Log-Message "Error while Downloading etl-api.zip file."
        Write-Host "Error while Downloading etl-api.zip file."
    }
}


if ($etlAction) {
    Write-Host "`n"
    Write-Host "Downloading etl-action.zip file."
    Log-Message "Downloading etl-action.zip file"
    Write-Host "Please wait..."
    try {
        $eacr = Invoke-RestMethod -Uri "https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-action.zip?ref=$branch"
        $eacrdul = $eacr.download_url
        Log-Message "Download Url $eacrdul."
        Invoke-WebRequest -Uri $eacrdul -OutFile "etl-action.zip"

        Write-Host "Downloading completed."
        Log-Message "Downloading completed.`n"

    }
    catch {
        Log-Message "Error while Downloading etl-action.zip file."
        Write-Host "Error while Downloading etl-action.zip file."
    }
}

if ($etlMapping) {
    Write-Host "`n"
    Write-Host "Downloading etl-mapping.zip file."
    Write-Host "Please wait..."
    Log-Message "Downloading etl-mapping.zip file"
    try {
        $emr = Invoke-RestMethod -Uri "https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-mapping.zip?ref=$branch"
        $emrdul = $emr.download_url
        Log-Message "Download Url $emrdul."
        Invoke-WebRequest -Uri $emrdul -OutFile "etl-mapping.zip"
        Write-Host "Downloading completed."
        Log-Message "Downloading completed.`n"

    }
    catch {
        Log-Message "Error while Downloading etl-mapping.zip file."
        Write-Host "Error while Downloading etl-mapping.zip file."
    }
}

if ($etlAudit) {
    Write-Host "`n"
    Write-Host "Downloading etl-office-audit.zip file."
    Log-Message "Downloading etl-office-audit.zip file"
    Write-Host "Please wait..."
    try {
        $eoar = Invoke-RestMethod -Uri "https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-office-audit.zip?ref=$branch"
        $eoardul = $eoar.download_url
        Log-Message "Download Url $eoardul."
        Invoke-WebRequest -Uri $eoardul -OutFile "etl-office-audit.zip"
        Write-Host "Downloading completed."
        Log-Message "Downloading completed.`n"

    }
    catch {
        Log-Message "Error while Downloading etl-office-audit.zip file."
        Write-Host "Error while Downloading etl-office-audit.zip file."
    }
}

if ($etlProcess) {
    Write-Host "`n"
    Write-Host "Downloading etl-process.zip file."
    Log-Message "Downloading etl-process.zip file"
    Write-Host "Please wait..."
    try {
        $epr = Invoke-RestMethod -Uri "https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-process.zip?ref=$branch"
        $eprdul = $epr.download_url
        Log-Message "Download Url $eprdul."
        Invoke-WebRequest -Uri $eprdul -OutFile "etl-process.zip"
        Write-Host "Downloading completed."
        Log-Message "Downloading completed.`n"

    }
    catch {
        Log-Message "Error while Downloading etl-process.zip file."
        Write-Host "Error while Downloading etl-process.zip file."
    }
}

if ($etlRenewal) {
    Write-Host "`n"
    Write-Host "Downloading etl-renewal.zip file."
    Log-Message "Downloading etl-renewal.zip file"
    Write-Host "Please wait..."
    try {
        $epr = Invoke-RestMethod -Uri "https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/etl-renewal.zip?ref=$branch"
        $eprdul = $epr.download_url
        Log-Message "Download Url $eprdul."
        Invoke-WebRequest -Uri $eprdul -OutFile "etl-renewal.zip"
        Write-Host "Downloading completed."
        Log-Message "Downloading completed.`n"

    }
    catch {
        Log-Message "Error while Downloading etl-process.zip file."
        Write-Host "Error while Downloading etl-process.zip file."
    }
}

if ($contentsyncAPI) {
    Write-Host "`n"
    Write-Host "Downloading contentsync-api.zip file."
    Log-Message "Downloading contentsync-api.zip file"
    Write-Host "Please wait..."
    try {
        $csar = Invoke-RestMethod -Uri "https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/contentsync-api.zip?ref=$branch"
        $csardul = $csar.download_url
        Log-Message "Download Url $csardul."
        Invoke-WebRequest -Uri $csardul -OutFile "contentsync-api.zip"
        Write-Host "Downloading completed."
        Log-Message "Downloading completed.`n"

    }
    catch {
        Log-Message "Error while Downloading contentsync-api.zip file."
        Write-Host "Error while Downloading contentsync-api.zip file."
    }
}

if ($contentsyncProcess) {
    Write-Host "`n"
    Write-Host "Downloading contentsync-process.zip file."
    Log-Message "Downloading contentsync-process.zip file"
    Write-Host "Please wait..."
    try {
        $cspr = Invoke-RestMethod -Uri "https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/contentsync-process.zip?ref=$branch"
        $csprdul = $cspr.download_url
        Log-Message "Download Url $csprdul."
        Invoke-WebRequest -Uri $csprdul -OutFile "contentsync-process.zip"
        Write-Host "Downloading completed."
        Log-Message "Downloading completed.`n"

    }
    catch {
        Log-Message "Error while Downloading contentsync-process.zip file."
        Write-Host "Error while Downloading contentsync-process.zip file."
    }
}

if ($contentsyncRetry) {
    Write-Host "`n"
    Write-Host "Downloading contentsync-retry.zip file."
    Log-Message "Downloading contentsync-retry.zip file"
    Write-Host "Please wait..."
    try {
        $csrr = Invoke-RestMethod -Uri "https://api.github.com/repos/Prosperoware/cam-azure-deployment/contents/contentsync-retry.zip?ref=$branch"
        $csrrdul = $csrr.download_url
        Log-Message "Download Url $csrrdul."
        Invoke-WebRequest -Uri $csrrdul -OutFile "contentsync-retry.zip"
        Write-Host "Downloading completed.`n"
        Log-Message "Downloading completed.`n"
    }
    catch {
        Log-Message "Error while Downloading contentsync-retry.zip file."
        Write-Host "Error while Downloading contentsync-retry.zip file."
    }
}

if ($etlAPI) {
    Write-Host "Deployment started for $etlAPI `n"
    Log-Message "Deployment started for $etlAPI."
    Write-Host "Please wait..."
    try {
        $response = Invoke-Expression "az webapp deploy --resource-group $resourceGroup --name $etlApi --src-path etl-api.zip --type zip --async false"
        #az webapp deploy --resource-group $resourceGroup --name $etlApi --src-path etl-api.zip --type zip --async false
        Log-Message $response
    }
    catch {
        Log-Message "Deployment failed for $etlAPI."
        Write-Host "Deployment failed for $etlAPI"
    }

}
if ($etlAction) {
    Write-Host "Deployment started for $etlAction `n"
    Log-Message "Deployment started for $etlAction."
    Write-Host "Please wait..."
    try {
        $response = Invoke-Expression "az webapp deploy --resource-group $resourceGroup --name $etlAction --src-path etl-action.zip --type zip --async false"
        # az webapp deploy --resource-group $resourceGroup --name $etlAction --src-path etl-action.zip --type zip --async false
        Log-Message $response
    }
    catch {
        Log-Message "Deployment failed for $etlAction."
        Write-Host "Deployment failed for $etlAction"
    }
}
if ($etlMapping) {
    Write-Host "Deployment started for $etlMapping `n"
    Log-Message "Deployment started for $etlMapping."
    Write-Host "Please wait..."
    try {
        $response = Invoke-Expression "az webapp deploy --resource-group $resourceGroup --name $etlMapping --src-path etl-mapping.zip --type zip --async false"
        # az webapp deploy --resource-group $resourceGroup --name $etlMapping --src-path etl-mapping.zip --type zip --async false
        Log-Message $response
    }
    catch {
        Log-Message "Deployment failed for $etlMapping."
        Write-Host "Deployment failed for $etlMapping"
    }
}
if ($etlAudit) {
    Write-Host "Deployment started for $etlAudit `n"
    Log-Message "Deployment started for $etlAudit."
    Write-Host "Please wait..."
    try {
        $response = Invoke-Expression "az webapp deploy --resource-group $resourceGroup --name $etlAudit --src-path etl-office-audit.zip --type zip --async false"
        # az webapp deploy --resource-group $resourceGroup --name $etlOfficeAudit --src-path etl-office-audit.zip --type zip --async false 
        Log-Message $response
    }
    catch {
        Log-Message "Deployment failed for $etlAudit."
        Write-Host "Deployment failed for $etlAudit"
    }
}

if ($etlProcess) {
    Write-Host "Deployment started for $etlProcess `n"
    Log-Message "Deployment started for $etlProcess."
    Write-Host "Please wait..."
    try {
        $response = Invoke-Expression "az webapp deploy --resource-group $resourceGroup --name $etlProcess --src-path etl-process.zip --type zip --async false"
        # az webapp deploy --resource-group $resourceGroup --name $etlProcess --src-path etl-process.zip --type zip --async false 
        Log-Message $response
    }
    catch {
        Log-Message "Deployment failed for $etlProcess."
        Write-Host "Deployment failed for $etlProcess"
    }
}

if ($etlRenewal) {
    Write-Host "Deployment started for $etlRenewal `n"
    Log-Message "Deployment started for $etlRenewal."
    Write-Host "Please wait..."
    try {
        $response = Invoke-Expression "az webapp deploy --resource-group $resourceGroup --name $etlRenewal --src-path etl-renewal.zip --type zip --async false"
        # az webapp deploy --resource-group $resourceGroup --name $etlRenewal --src-path etl-renewal.zip --type zip --async false
        Log-Message $response
    }
    catch {
        Log-Message "Deployment failed for $etlRenewal."
        Write-Host "Deployment failed for $etlRenewal"
    }
}

if ($contentsyncAPI) {
    Write-Host "Downloading contentsync.api.zip file."
    Log-Message "Deployment started for $contentsyncAPI."
    Write-Host "Please wait..."
    try {
        $response = Invoke-Expression "az webapp deploy --resource-group $resourceGroup --name $contentSyncApi --src-path contentsync-api.zip --type zip --async false"
        # az webapp deploy --resource-group $resourceGroup --name $contentSyncApi --src-path contentsync-api.zip --type zip --async false
        Log-Message $response
    }
    catch {
        Log-Message "Deployment failed for $contentsyncAPI."
        Write-Host "Deployment failed for $contentsyncAPI"
    }
}
if ($contentsyncProcess) {
    Write-Host "Downloading contentsync-process.zip file."
    Log-Message "Deployment started for $contentsyncProcess."
    Write-Host "Please wait..."
    try {
        $response = Invoke-Expression "az webapp deploy --resource-group $resourceGroup --name $contentSyncProcess --src-path contentsync-process.zip --type zip --async false"
        # az webapp deploy --resource-group $resourceGroup --name $contentSyncProcess --src-path contentsync-process.zip --type zip --async false
        Log-Message $response
    }
    catch {
        Log-Message "Deployment failed for $contentsyncProcess."
        Write-Host "Deployment failed for $contentsyncProcess"
    }
}
if ($contentsyncRetry) { 
    Write-Host "Downloading contentsync-retry.zip file."
    Log-Message "Deployment started for $contentsyncRetry."
    Write-Host "Please wait..."
    try {
        $response = Invoke-Expression "az webapp deploy --resource-group $resourceGroup --name $contentSyncRetry --src-path contentsync-retry.zip --type zip --async false"
        # az webapp deploy --resource-group $resourceGroup --name $contentSyncRetry --src-path contentsync-retry.zip --type zip --async false
        Log-Message $response
    }
    catch {
        Log-Message "Deployment failed for $contentsyncRetry."
        Write-Host "Deployment failed for $contentsyncRetry"
    } 
}

Log-Message "Script ended." 
Write-Host "Script ended."