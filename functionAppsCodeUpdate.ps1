[CmdletBinding()]
param(
    [string]$Branch = "master",
    [string]$GitHubRepositoryURL = "https://api.github.com/repos/Prosperoware/cam-azure-deployment"
)

$maxRetries = 3
$selectedSubscriptionId = $null
$resourceGroupRes = $null
$logFileTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFilePath = "CAM_Azure_Stack_log_$logFileTimestamp.txt"

function Log-Message {
    param(
        [Parameter(Mandatory = $true)][string] $Message,
        [Parameter(Mandatory = $false)] [ValidateSet("INFO", "WARNING", "ERROR")] [string] $Level = "INFO",
        [Parameter(Mandatory = $false)] [bool] $WriteToHost = $true
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] - $Message"
    $logEntry | Out-File -FilePath $logFilePath -Append
    
    if ($WriteToHost) {
        $foregroundColor = "White"
        if ($Level -eq "WARNING") {
            $foregroundColor = "Yellow"
        }
        elseif ($Level -eq "ERROR") {
            $foregroundColor = "Red"
        }
        Write-Host $Message -ForegroundColor $foregroundColor
    }
}

function Select-AzureSubscription {
    $subscriptionId = $null
    $retryCount = 0
    do {
        try {
            az login | Out-Null
            $subscriptions = az account list --all | ConvertFrom-Json
            if ($subscriptions.Count -gt 0) {
                if ($subscriptions.Count -gt 1) {
                    Write-Host "------------------------------------------------------------------------"
                    Write-Host "Please select a subscription from the list below:"
                    for ($i = 0; $i -lt $subscriptions.Count; $i++) {
                        Write-Host "$($i + 1): $($subscriptions[$i].name) (ID: $($subscriptions[$i].id))"
                    }
                    do {
                        Write-Host "------------------------------------------------------------------------"
                        $input = Read-Host "Enter the index of the desired subscription (1-$($subscriptions.Count))"
                        $choice = $input -as [int]
                    } until ($choice -gt 0 -and $choice -le $subscriptions.Count)
                } else {
                    $choice = 1
                }
                $selectedSubscription = $subscriptions[$choice - 1]
                $subscriptionId = $selectedSubscription.id
                az account set --subscription $subscriptionId
                Log-Message "Azure subscription: ""$($selectedSubscription.name) (ID: $($subscriptionId))"" was selected"
                break
            } else {
                Log-Message "No subscriptions found." -Level "ERROR"
                break
            }
        }
        catch {
            Log-Message "Failed to retrieve subscriptions. Please check your internet connection and try again." -Level "ERROR"
        }
        $retryCount++
    } while (-not $subscriptionId -and $retryCount -lt $maxRetries)
    return $subscriptionId
}

function Select-ResourceGroup {
    param(
        [Parameter(Mandatory = $true)][string] $SubscriptionId
    )
    $resourceGroupName = $null
    $retryCount = 0
    do {
        if (-not $SubscriptionId) {
            Log-Message "Invalid subscription selected" -Level "ERROR"
            break
        }
        try {
            $resourceGroups = az group list --subscription $SubscriptionId | ConvertFrom-Json
            if ($resourceGroups.Count -gt 0) {
                if ($resourceGroups.Count -gt 1) {
                    Write-Host "------------------------------------------------------------------------"
                    Write-Host "Please select a resource group from the list below:"
                    for ($i = 0; $i -lt $resourceGroups.Count; $i++) {
                        Write-Host "$($i + 1): $($resourceGroups[$i].name)"
                    }
                    do {
                        Write-Host "------------------------------------------------------------------------"
                        $input = Read-Host "Enter the index of the desired resource group (1-$($resourceGroups.Count))"
                        $choice = $input -as [int]
                    } until ($choice -gt 0 -and $choice -le $resourceGroups.Count)
                } else {
                    $choice = 1
                }
                $resourceGroupName = $resourceGroups[$choice - 1].name
                Log-Message "The resource group: ""$resourceGroupName"" was selected"
                break
            } else {
                Log-Message "No resource groups found." -Level "ERROR"
                break
            }
        }
        catch {
            Log-Message "Failed to retrieve the resource group. Either it doesn't exist or there's an authentication issue." -Level "ERROR"
        }
        $retryCount++
    } while ($retryCount -lt $maxRetries)
    return $resourceGroupName
}

function Download-and-Upgrade {
    param(
        [string]$AppName,
        [string]$FileName,
        [Parameter(Mandatory = $true)][string] $ResourceGroupName
    )
    $downloadUri = "$GitHubRepositoryURL/contents/$FileName.zip?ref=$Branch"
    Write-Host "------------------------------------------------------------------------"
    Log-Message "Downloading ""$FileName.zip"" file."
    Write-Host "Please wait..."
    try {
        $apiResponse = Invoke-RestMethod -Uri $downloadUri
        $downloadUrl = $apiResponse.download_url
        Log-Message "Downloading from the URL: $downloadUrl."
        Invoke-WebRequest -Uri $downloadUrl -OutFile "$FileName.zip"
        Log-Message "Upgrade started for $AppName"
        $response = az webapp deploy --resource-group $ResourceGroupName --name $AppName --src-path "$FileName.zip" --type zip --async true
        Log-Message "Upgrade response: $response" -WriteToHost $false
        Log-Message """$AppName"" upgrade succeeded."
    }
    catch {
        Log-Message "Upgrade failed for ""$AppName"" : Error during download/upgrade." -Level "ERROR"
    }
}

Write-Host "Logging to file $logFilePath"

Log-Message "------------------------------------ Starting script execution ------------------------------------"
Log-Message "Upgrading CAM Azure Stack from ""$Branch"" branch"
$selectedSubscriptionId = Select-AzureSubscription
if (-not $selectedSubscriptionId) {
    Log-Message "Login to Azure failed. Exiting" -Level "ERROR"
    exit 1
}

$resourceGroupRes = Select-ResourceGroup -subscriptionId $selectedSubscriptionId
if (-not $resourceGroupRes) {
    Log-Message "Failed to retrieve the resource group." -Level "ERROR"
    exit 1
}

$functionApps = az functionapp list --resource-group $resourceGroupRes --query "[].name" --output tsv

if (!$functionApps) {
    Log-Message "No function apps found in the resource group ""$resourceGroupRes""." -Level "ERROR"
    exit 1
}

$stackApps = @{
    "etl-api" = "etl-api";
    "etl-action" = "etl-action";
    "etl-renewal" = "etl-renewal";
    "etl-mapping" = "etl-mapping";
    "etl-office-audit" = "etl-office-audit";
    "etl-process" = "etl-process";
    "contentsync-api" = "contentsync-api";
    "contentsync-process" = "contentsync-process";
    "contentsync-retry" = "contentsync-retry"
}

$matchingAppsCount = 0
foreach ($functionApp in $functionApps) {
    foreach ($stackApp in $stackApps.Keys) {
        if ($functionApp -like "*$stackApp*") {
            Log-Message "The function app ""$functionApp"" matched with the stack app $stackApp"
            Download-and-Upgrade -AppName $functionApp -FileName $stackApps[$stackApp] -ResourceGroupName $resourceGroupRes
            $matchingAppsCount++
        }
    }
}

if ($matchingAppsCount -eq 0) {
    Log-Message "No matching CAM function apps found in the resource group ""$resourceGroupRes""." -Level "ERROR"
    exit 1
}

Log-Message "------------------------------------ Finished script execution ------------------------------------"
