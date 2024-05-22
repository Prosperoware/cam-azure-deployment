[CmdletBinding()]
param(
    [string]$Branch = "master",
    [string]$GitHubRepositoryURL = "https://api.github.com/repos/Prosperoware/cam-azure-deployment"
)

$maxRetries = 3
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
    $success = $false
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
                        $input = Read-Host "Enter the number of the desired subscription (1-$($subscriptions.Count))"
                        $choice = $input -as [int]
                    } until ($choice -gt 0 -and $choice -le $subscriptions.Count)
                } else {
                    $choice = 1
                }
                $selectedSubscription = $subscriptions[$choice - 1]
                az account set --subscription $selectedSubscription.id
                Log-Message "Azure subscription: ""$($selectedSubscription.name)"" was selected"
                $success = $true
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
    } while (-not $success -and $retryCount -lt $maxRetries)
    return $success
}

function Select-ResourceGroup {
	$retryCount = 0
    do {
        try {
			Write-Host "------------------------------------------------------------------------"
            $resourceGroup = Read-Host "Please enter the resource group name"
            $response = az group show --name $resourceGroup | ConvertFrom-Json
            $resourceGroupName = $response.name
			if ($resourceGroupName -eq $resourceGroup) {
				Log-Message "The resource group ""$resourceGroupName"" was found"
				return $resourceGroupName
			}
        }
        catch {
            Log-Message "Failed to retrieve the resource group. Either it doesn't exist or there's an authentication issue." -Level "ERROR"
        }
		$retryCount++
    } while ($retryCount -lt $maxRetries)
	return $null
}

function Download-and-Upgrade {
	param(
        [string]$AppName,
        [string]$FileName
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
		$response = az webapp deployment source config-zip --resource-group $resourceGroupRes --name $AppName --src "$FileName.zip"
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
$subscriptionSelected = Select-AzureSubscription
if (-not $subscriptionSelected) {
	Log-Message "Login to Azure failed. Exiting" -Level "ERROR"
    exit 1
}

$resourceGroupRes = Select-ResourceGroup
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
            Download-and-Upgrade -AppName $functionApp -FileName $stackApps[$stackApp]
			$matchingAppsCount++
		}
	}
}

if ($matchingAppsCount -eq 0) {
	Log-Message "No matching CAM function apps found in the resource group ""$resourceGroupRes""." -Level "ERROR"
    exit 1
}

Log-Message "------------------------------------ Finished script execution ------------------------------------"
