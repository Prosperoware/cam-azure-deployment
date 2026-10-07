<#
.SYNOPSIS
    Configures AAD (Entra ID) authentication for the CAM Azure stack: Cosmos DB
    data-plane RBAC, Storage Blob data-plane RBAC, Service Bus data-plane RBAC,
    and Azure MySQL Flexible Server AAD administration.

.DESCRIPTION
    Based on functionAppsCodeUpdate-LocalZip.ps1 (same subscription/resource-group
    selection, logging and retry conventions). Instead of deploying function app
    zips, this script provisions the Azure-side prerequisites required by the
    application's AAD auth code paths (cosmos_useaadauth / useAadAuth flags):

      Cosmos DB : grants the app's managed identity the "Cosmos DB Built-in Data
                  Contributor" data-plane role, and (optionally) disables
                  key-based (local) auth for AAD-only enforcement.
      Storage   : grants the identity "Storage Blob Data Contributor" so Blob
                  reads/writes (appconfig, errors.properties, encrypted bucket)
                  keep working after AZURE_CLIENT_ID selects this UAMI for
                  DefaultAzureCredential.
      Service   : grants the identity "Azure Service Bus Data Owner" so API (send)
       Bus        and process/retry (receive) apps keep working after
                  AZURE_CLIENT_ID selects this UAMI for DefaultAzureCredential.
      MySQL     : sets an AAD administrator, enforces TLS, and prints the
                  CREATE AADUSER / GRANT SQL to create the managed-identity DB user.
      Function  : attaches the user-assigned managed identity to the selected
       Apps       Function App(s), sets AZURE_CLIENT_ID (so DefaultAzureCredential
                  picks that identity) and restarts them.

    The managed identity is resolved either by user-assigned identity name, or by
    supplying its principal (object) and client (application) IDs directly. Note that
    attaching the identity to Function Apps requires its ARM resource id, which is only
    resolved when an -IdentityName is supplied.

.PARAMETER IdentityName
    User-assigned managed identity name (in the selected resource group). Used to
    resolve principal/client IDs and as the default MySQL AAD DB user name.

.PARAMETER IdentityPrincipalId
    Managed identity principal (object) ID. Overrides lookup by IdentityName.

.PARAMETER IdentityClientId
    Managed identity client (application) ID. Used in the CREATE AADUSER statement.

.PARAMETER CosmosAccountName
    Cosmos DB account name to configure. If omitted, Cosmos config is prompted/skipped.

.PARAMETER DisableCosmosLocalAuth
    Switch. When set, disables Cosmos key-based auth (disableLocalAuth=true).

.PARAMETER StorageAccountName
    Storage account name to grant Blob data-plane RBAC on. If omitted, Storage
    config is prompted/skipped.

.PARAMETER ServiceBusNamespace
    Service Bus namespace name to grant data-plane RBAC on. If omitted, Service Bus
    config is prompted/skipped.

.PARAMETER MySqlServerName
    Azure MySQL Flexible Server name to configure. If omitted, MySQL config is prompted/skipped.

.PARAMETER MySqlDatabase
    Database name to grant privileges on (e.g. contentsync_dev).

.PARAMETER MySqlAdminObjectId
    AAD admin object ID for MySQL. Defaults to the signed-in user.

.PARAMETER MySqlAdminName
    AAD admin display name / UPN for MySQL. Defaults to the signed-in user.

.PARAMETER FunctionAppName
    A single Function App to attach the identity to. Overrides prefix/domain and the
    interactive picker.

.PARAMETER FunctionPrefix
    Non-interactive filter: attach the identity to all Function Apps whose name starts
    with this prefix (combine with -Domain to narrow the whole stack).

.PARAMETER Domain
    Non-interactive filter: restrict matched Function Apps to those whose name contains
    this domain segment.

.PARAMETER SkipSetAzureClientId
    Switch. Attach the identity but do NOT set the AZURE_CLIENT_ID app setting (e.g. when
    it is managed via IaC).

.PARAMETER SkipRestart
    Switch. Do not restart the Function App(s) after attaching the identity / setting
    AZURE_CLIENT_ID (restart later during your deploy window).

.EXAMPLE
    .\configureAadAuth-AzureStack.ps1 -IdentityName "cam-app-identity" -CosmosAccountName "contentsyncdev-cosmos" -StorageAccountName "strgdevsingledevio" -ServiceBusNamespace "servicebus-devsingledev-io" -MySqlServerName "az-contentsync-dev-mysql" -MySqlDatabase "contentsync_dev"

.EXAMPLE
    .\configureAadAuth-AzureStack.ps1 -IdentityPrincipalId "<oid>" -IdentityClientId "<appid>" -CosmosAccountName "contentsyncdev-cosmos" -DisableCosmosLocalAuth

.EXAMPLE
    # Whole-stack: grant Cosmos/Storage/Service Bus/MySQL and attach the identity to every matching Function App.
    .\configureAadAuth-AzureStack.ps1 -IdentityName "id-cam-storage" -CosmosAccountName "cosmos-devsingledev-io" -StorageAccountName "strgdevsingledevio" -ServiceBusNamespace "servicebus-devsingledev-io" -FunctionPrefix "devsingledev" -Domain "io"

.EXAMPLE
    # Single Function App only (attach identity + set AZURE_CLIENT_ID + restart).
    .\configureAadAuth-AzureStack.ps1 -IdentityName "id-cam-storage" -FunctionAppName "devsingledev-io-contentsync-api"
#>
[CmdletBinding()]
param(
    [string]$IdentityName = "",
    [string]$IdentityPrincipalId = "",
    [string]$IdentityClientId = "",
    [string]$CosmosAccountName = "",
    [switch]$DisableCosmosLocalAuth,
    [string]$StorageAccountName = "",
    [string]$ServiceBusNamespace = "",
    [string]$MySqlServerName = "",
    [string]$MySqlDatabase = "",
    [string]$MySqlAdminObjectId = "",
    [string]$MySqlAdminName = "",
    [string]$FunctionAppName = "",
    [string]$FunctionPrefix = "",
    [string]$Domain = "",
    [switch]$SkipSetAzureClientId,
    [switch]$SkipRestart
)

$maxRetries = 3
$selectedSubscriptionId = $null
$resourceGroupRes = $null
$logFileTimestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFilePath = "CAM_Azure_AadAuth_log_$logFileTimestamp.txt"

# Well-known Cosmos DB SQL "Built-in Data Contributor" role definition suffix.
$cosmosDataContributorRoleName = "Cosmos DB Built-in Data Contributor"
$cosmosDataContributorRoleGuid = "00000000-0000-0000-0000-000000000002"
# Required once AZURE_CLIENT_ID selects the UAMI — BlobUtils uses DefaultAzureCredential for appconfig/errors/etc.
$storageBlobDataContributorRoleName = "Storage Blob Data Contributor"
# Covers send (API createCopyJob) and receive (process/retry workers) after AZURE_CLIENT_ID selects the UAMI.
$serviceBusDataOwnerRoleName = "Azure Service Bus Data Owner"
# OSS RDBMS AAD token scope (informational; used when connecting to run SQL).
$mysqlAadScope = "https://ossrdbms-aad.database.windows.net/.default"

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
                        $userInput = Read-Host "Enter the index of the desired subscription (1-$($subscriptions.Count))"
                        $choice = $userInput -as [int]
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
                        $userInput = Read-Host "Enter the index of the desired resource group (1-$($resourceGroups.Count))"
                        $choice = $userInput -as [int]
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

function Prompt-IfEmpty {
    param(
        [Parameter(Mandatory = $false)][AllowEmptyString()][string] $Value = "",
        [Parameter(Mandatory = $true)][string] $Message
    )
    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }
    return (Read-Host $Message)
}

function Select-ResourceByName {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]] $Names,
        [Parameter(Mandatory = $true)][string] $ResourceLabel
    )
    # Lets the user pick a resource by index, or skip. Returns $null when skipped
    # or when none are available.
    if (-not $Names -or $Names.Count -eq 0) {
        Log-Message "No $ResourceLabel resources found in the resource group." -Level "WARNING"
        return $null
    }

    Write-Host "------------------------------------------------------------------------"
    Write-Host "Please select the $ResourceLabel resource where the changes are needed:"
    for ($i = 0; $i -lt $Names.Count; $i++) {
        Write-Host "$($i + 1): $($Names[$i])"
    }
    Write-Host "0: Skip $ResourceLabel configuration"
    do {
        Write-Host "------------------------------------------------------------------------"
        $userInput = Read-Host "Enter the index of the desired $ResourceLabel resource (0-$($Names.Count))"
        $choice = $userInput -as [int]
    } until ($null -ne $choice -and $choice -ge 0 -and $choice -le $Names.Count)

    if ($choice -eq 0) {
        Log-Message "Skipping $ResourceLabel configuration (user chose to skip)." -Level "WARNING"
        return $null
    }
    $selected = $Names[$choice - 1]
    Log-Message "The $ResourceLabel resource: ""$selected"" was selected"
    return $selected
}

function Select-CosmosAccount {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName
    )
    # If provided as a parameter, honor it; otherwise list and prompt.
    if (-not [string]::IsNullOrWhiteSpace($CosmosAccountName)) {
        Log-Message "Using Cosmos DB account from parameter: ""$CosmosAccountName"""
        return $CosmosAccountName
    }
    try {
        $names = @(az cosmosdb list --resource-group $ResourceGroupName --query "[].name" --output tsv)
        return (Select-ResourceByName -Names $names -ResourceLabel "Cosmos DB account")
    }
    catch {
        Log-Message "Failed to list Cosmos DB accounts in ""$ResourceGroupName""." -Level "ERROR"
        return $null
    }
}

function Select-MySqlServer {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName
    )
    if (-not [string]::IsNullOrWhiteSpace($MySqlServerName)) {
        Log-Message "Using MySQL flexible server from parameter: ""$MySqlServerName"""
        return $MySqlServerName
    }
    try {
        $names = @(az mysql flexible-server list --resource-group $ResourceGroupName --query "[].name" --output tsv)
        return (Select-ResourceByName -Names $names -ResourceLabel "MySQL flexible server")
    }
    catch {
        Log-Message "Failed to list MySQL flexible servers in ""$ResourceGroupName""." -Level "ERROR"
        return $null
    }
}

function Select-StorageAccount {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName
    )
    if (-not [string]::IsNullOrWhiteSpace($StorageAccountName)) {
        Log-Message "Using Storage account from parameter: ""$StorageAccountName"""
        return $StorageAccountName
    }
    try {
        $names = @(az storage account list --resource-group $ResourceGroupName --query "[].name" --output tsv)
        return (Select-ResourceByName -Names $names -ResourceLabel "Storage account")
    }
    catch {
        Log-Message "Failed to list Storage accounts in ""$ResourceGroupName""." -Level "ERROR"
        return $null
    }
}

function Select-ServiceBusNamespace {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName
    )
    if (-not [string]::IsNullOrWhiteSpace($ServiceBusNamespace)) {
        Log-Message "Using Service Bus namespace from parameter: ""$ServiceBusNamespace"""
        return $ServiceBusNamespace
    }
    try {
        $names = @(az servicebus namespace list --resource-group $ResourceGroupName --query "[].name" --output tsv)
        return (Select-ResourceByName -Names $names -ResourceLabel "Service Bus namespace")
    }
    catch {
        Log-Message "Failed to list Service Bus namespaces in ""$ResourceGroupName""." -Level "ERROR"
        return $null
    }
}

function Resolve-ManagedIdentity {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName
    )
    # Returns a hashtable with PrincipalId, ClientId, Name and ResourceId.
    $result = @{ PrincipalId = $IdentityPrincipalId; ClientId = $IdentityClientId; Name = $IdentityName; ResourceId = "" }

    if (-not [string]::IsNullOrWhiteSpace($IdentityPrincipalId)) {
        Log-Message "Using managed identity principal id provided via parameter."
        if ([string]::IsNullOrWhiteSpace($result.Name)) { $result.Name = "app-identity" }
        # Best-effort resolve the ARM resource id (required to attach the identity to
        # Function Apps) when a name is also available.
        if (-not [string]::IsNullOrWhiteSpace($IdentityName)) {
            try {
                $byName = az identity show --name $IdentityName --resource-group $ResourceGroupName | ConvertFrom-Json
                if ($byName) { $result.ResourceId = $byName.id }
            }
            catch { }
        }
        return $result
    }

    $name = Prompt-IfEmpty -Value $IdentityName -Message "Enter the user-assigned managed identity name"
    try {
        $identity = az identity show --name $name --resource-group $ResourceGroupName | ConvertFrom-Json
        if (-not $identity) { throw "not found" }
        $result.PrincipalId = $identity.principalId
        $result.ClientId = $identity.clientId
        $result.Name = $name
        $result.ResourceId = $identity.id
        Log-Message "Resolved managed identity ""$name"" (principalId: $($identity.principalId))"
    }
    catch {
        Log-Message "Could not find user-assigned identity ""$name"" in ""$ResourceGroupName""." -Level "ERROR"
    }
    return $result
}

function Configure-CosmosAadAuth {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName,
        [Parameter(Mandatory = $true)][hashtable] $Identity,
        [Parameter(Mandatory = $false)][string] $AccountName
    )
    Write-Host "------------------------------------------------------------------------"
    $account = $AccountName
    if ([string]::IsNullOrWhiteSpace($account)) {
        Log-Message "Skipping Cosmos DB configuration (no account selected)." -Level "WARNING"
        return
    }
    if ([string]::IsNullOrWhiteSpace($Identity.PrincipalId)) {
        Log-Message "Skipping Cosmos DB configuration: managed identity principal id is unknown." -Level "ERROR"
        return
    }

    try {
        $cosmosId = az cosmosdb show --name $account --resource-group $ResourceGroupName --query id --output tsv
        if ([string]::IsNullOrWhiteSpace($cosmosId)) { throw "Cosmos account not found" }

        $roleDefId = az cosmosdb sql role definition list --account-name $account --resource-group $ResourceGroupName --query "[?roleName=='$cosmosDataContributorRoleName'].id | [0]" --output tsv
        if ([string]::IsNullOrWhiteSpace($roleDefId)) {
            $roleDefId = "$cosmosId/sqlRoleDefinitions/$cosmosDataContributorRoleGuid"
            Log-Message "Falling back to well-known Data Contributor role definition id." -Level "WARNING"
        }
        Log-Message "Cosmos role definition: $roleDefId"

        Log-Message "Creating Cosmos data-plane role assignment for identity $($Identity.PrincipalId)..."
        az cosmosdb sql role assignment create `
            --account-name $account `
            --resource-group $ResourceGroupName `
            --role-definition-id $roleDefId `
            --principal-id $Identity.PrincipalId `
            --scope $cosmosId `
            --output none
        Log-Message "Cosmos role assignment created (or already existed)."

        $shouldDisable = $DisableCosmosLocalAuth
        if (-not $shouldDisable) {
            $answer = Read-Host "Disable key-based (local) auth on Cosmos account for AAD-only? [y/N]"
            $shouldDisable = ($answer -match '^[Yy]$')
        }
        if ($shouldDisable) {
            Log-Message "Disabling Cosmos local auth. Ensure ALL clients use AAD first." -Level "WARNING"
            az resource update --ids $cosmosId --set properties.disableLocalAuth=true --latest-include-preview --output none
            Log-Message "Cosmos local auth disabled (disableLocalAuth=true)."
        } else {
            Log-Message "Leaving Cosmos key-based auth enabled (backward compatible)."
        }
    }
    catch {
        Log-Message "Cosmos DB configuration failed for ""$account"": $($_.Exception.Message)" -Level "ERROR"
    }
}

function Configure-StorageAadAuth {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName,
        [Parameter(Mandatory = $true)][hashtable] $Identity,
        [Parameter(Mandatory = $false)][string] $AccountName
    )
    Write-Host "------------------------------------------------------------------------"
    $account = $AccountName
    if ([string]::IsNullOrWhiteSpace($account)) {
        Log-Message "Skipping Storage configuration (no account selected)." -Level "WARNING"
        return
    }
    if ([string]::IsNullOrWhiteSpace($Identity.PrincipalId)) {
        Log-Message "Skipping Storage configuration: managed identity principal id is unknown." -Level "ERROR"
        return
    }

    try {
        $accountId = az storage account show --name $account --resource-group $ResourceGroupName --query id --output tsv
        if ([string]::IsNullOrWhiteSpace($accountId)) { throw "Storage account not found" }

        # Idempotent: skip if the assignment already exists for this principal/role/scope.
        $existing = az role assignment list `
            --assignee-object-id $Identity.PrincipalId `
            --scope $accountId `
            --role $storageBlobDataContributorRoleName `
            --query "[0].id" `
            --output tsv 2>$null

        if (-not [string]::IsNullOrWhiteSpace($existing)) {
            Log-Message "Storage role ""$storageBlobDataContributorRoleName"" already assigned to identity $($Identity.PrincipalId)."
            return
        }

        Log-Message "Creating Storage role assignment (""$storageBlobDataContributorRoleName"") for identity $($Identity.PrincipalId)..."
        az role assignment create `
            --assignee-object-id $Identity.PrincipalId `
            --assignee-principal-type ServicePrincipal `
            --role $storageBlobDataContributorRoleName `
            --scope $accountId `
            --output none
        if ($LASTEXITCODE -eq 0) {
            Log-Message "Storage role assignment created. Allow a few minutes for RBAC propagation."
        }
        else {
            Log-Message "Storage role assignment create failed for ""$account""." -Level "ERROR"
        }
    }
    catch {
        Log-Message "Storage configuration failed for ""$account"": $($_.Exception.Message)" -Level "ERROR"
    }
}

function Configure-ServiceBusAadAuth {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName,
        [Parameter(Mandatory = $true)][hashtable] $Identity,
        [Parameter(Mandatory = $false)][string] $NamespaceName
    )
    Write-Host "------------------------------------------------------------------------"
    $namespace = $NamespaceName
    if ([string]::IsNullOrWhiteSpace($namespace)) {
        Log-Message "Skipping Service Bus configuration (no namespace selected)." -Level "WARNING"
        return
    }
    if ([string]::IsNullOrWhiteSpace($Identity.PrincipalId)) {
        Log-Message "Skipping Service Bus configuration: managed identity principal id is unknown." -Level "ERROR"
        return
    }

    try {
        $namespaceId = az servicebus namespace show --name $namespace --resource-group $ResourceGroupName --query id --output tsv
        if ([string]::IsNullOrWhiteSpace($namespaceId)) { throw "Service Bus namespace not found" }

        # Idempotent: skip if the assignment already exists for this principal/role/scope.
        $existing = az role assignment list `
            --assignee-object-id $Identity.PrincipalId `
            --scope $namespaceId `
            --role $serviceBusDataOwnerRoleName `
            --query "[0].id" `
            --output tsv 2>$null

        if (-not [string]::IsNullOrWhiteSpace($existing)) {
            Log-Message "Service Bus role ""$serviceBusDataOwnerRoleName"" already assigned to identity $($Identity.PrincipalId)."
            return
        }

        Log-Message "Creating Service Bus role assignment (""$serviceBusDataOwnerRoleName"") for identity $($Identity.PrincipalId)..."
        az role assignment create `
            --assignee-object-id $Identity.PrincipalId `
            --assignee-principal-type ServicePrincipal `
            --role $serviceBusDataOwnerRoleName `
            --scope $namespaceId `
            --output none
        if ($LASTEXITCODE -eq 0) {
            Log-Message "Service Bus role assignment created. Allow a few minutes for RBAC propagation."
        }
        else {
            Log-Message "Service Bus role assignment create failed for ""$namespace""." -Level "ERROR"
        }
    }
    catch {
        Log-Message "Service Bus configuration failed for ""$namespace"": $($_.Exception.Message)" -Level "ERROR"
    }
}

function Configure-MySqlAadAuth {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName,
        [Parameter(Mandatory = $true)][hashtable] $Identity,
        [Parameter(Mandatory = $false)][string] $ServerName
    )
    Write-Host "------------------------------------------------------------------------"
    $server = $ServerName
    if ([string]::IsNullOrWhiteSpace($server)) {
        Log-Message "Skipping MySQL configuration (no server selected)." -Level "WARNING"
        return
    }
    $database = Prompt-IfEmpty -Value $MySqlDatabase -Message "Enter the database name to grant privileges on"

    $adminOid = $MySqlAdminObjectId
    $adminName = $MySqlAdminName
    if ([string]::IsNullOrWhiteSpace($adminOid)) {
        $adminOid = az ad signed-in-user show --query id --output tsv 2>$null
    }
    if ([string]::IsNullOrWhiteSpace($adminName)) {
        $adminName = az ad signed-in-user show --query userPrincipalName --output tsv 2>$null
        if ([string]::IsNullOrWhiteSpace($adminName)) { $adminName = "aad-admin" }
    }
    if ([string]::IsNullOrWhiteSpace($adminOid)) {
        Log-Message "MySQL AAD admin object id is required; skipping MySQL configuration." -Level "ERROR"
        return
    }

    try {
        az extension show --name rdbms-connect --output none 2>$null
        if ($LASTEXITCODE -ne 0) {
            az extension add --name rdbms-connect --yes --output none
        }

        Log-Message "Setting AAD administrator ($adminName) on MySQL server ""$server""..."
        $adArgs = @(
            "mysql", "flexible-server", "ad-admin", "create",
            "--resource-group", $ResourceGroupName,
            "--server-name", $server,
            "--object-id", $adminOid,
            "--display-name", $adminName
        )
        if (-not [string]::IsNullOrWhiteSpace($Identity.Name)) {
            $adArgs += @("--identity", $Identity.Name)
        }
        & az @adArgs --output none
        if ($LASTEXITCODE -eq 0) {
            Log-Message "MySQL AAD admin configured."
        } else {
            Log-Message "AAD admin create failed or already set. Ensure a user-assigned identity is attached to the server for AAD auth." -Level "WARNING"
        }

        Log-Message "Enforcing TLS (require_secure_transport=ON)..."
        az mysql flexible-server parameter set --resource-group $ResourceGroupName --server-name $server --name require_secure_transport --value ON --output none 2>$null
        if ($LASTEXITCODE -eq 0) {
            Log-Message "TLS enforced."
        } else {
            Log-Message "Could not set require_secure_transport; set it manually." -Level "WARNING"
        }

        $mysqlUser = if (-not [string]::IsNullOrWhiteSpace($Identity.Name)) { $Identity.Name } else { "app-identity" }
        $clientId = if (-not [string]::IsNullOrWhiteSpace($Identity.ClientId)) { $Identity.ClientId } else { "<managed-identity-client-id>" }
        $dbName = if (-not [string]::IsNullOrWhiteSpace($database)) { $database } else { "<database>" }

        Log-Message "Run the following SQL as the AAD admin to create the managed-identity DB user:"
        Write-Host "------------------------------------------------------------------------"
        Write-Host "-- Obtain a token:  az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv"
        Write-Host "-- Connect:         mysql -h $server.mysql.database.azure.com -u '$adminName' --enable-cleartext-plugin --password=""<token>"" --ssl-mode=REQUIRED"
        Write-Host ""
        Write-Host "SET aad_auth_validate_oids_in_tenant = OFF;"
        Write-Host "CREATE AADUSER '$mysqlUser' IDENTIFIED BY '$clientId';"
        Write-Host "GRANT ALL PRIVILEGES ON ``$dbName``.* TO '$mysqlUser'@'%';"
        Write-Host "FLUSH PRIVILEGES;"
        Write-Host "------------------------------------------------------------------------"
        Log-Message "IMPORTANT: set the app config 'username' for this environment to ""$mysqlUser"" so it connects as the AAD DB user."
    }
    catch {
        Log-Message "MySQL configuration failed for ""$server"": $($_.Exception.Message)" -Level "ERROR"
    }
}

function Select-FunctionApps {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName
    )
    # Returns an array of Function App names to configure (may be empty = skip).
    if (-not [string]::IsNullOrWhiteSpace($FunctionAppName)) {
        Log-Message "Using Function App from parameter: ""$FunctionAppName"""
        return @($FunctionAppName)
    }

    try {
        $names = @(az functionapp list --resource-group $ResourceGroupName --query "[].name" --output tsv)
    }
    catch {
        Log-Message "Failed to list Function Apps in ""$ResourceGroupName""." -Level "ERROR"
        return @()
    }
    if (-not $names -or $names.Count -eq 0) {
        Log-Message "No Function Apps found in the resource group." -Level "WARNING"
        return @()
    }

    # Non-interactive: filter by prefix/domain when provided (whole-stack mode).
    if (-not [string]::IsNullOrWhiteSpace($FunctionPrefix) -or -not [string]::IsNullOrWhiteSpace($Domain)) {
        $filtered = @($names | Where-Object {
                ([string]::IsNullOrWhiteSpace($FunctionPrefix) -or $_.StartsWith($FunctionPrefix)) -and
                ([string]::IsNullOrWhiteSpace($Domain) -or $_ -like "*$Domain*")
            })
        if ($filtered.Count -eq 0) {
            Log-Message "No Function Apps matched prefix ""$FunctionPrefix"" / domain ""$Domain""." -Level "WARNING"
            return @()
        }
        Log-Message "Selected $($filtered.Count) Function App(s) by prefix/domain filter: $($filtered -join ', ')"
        return $filtered
    }

    # Interactive multi-select.
    Write-Host "------------------------------------------------------------------------"
    Write-Host "Select the Function App(s) to attach the managed identity to:"
    for ($i = 0; $i -lt $names.Count; $i++) {
        Write-Host "$($i + 1): $($names[$i])"
    }
    Write-Host "A: All listed Function Apps"
    Write-Host "0: Skip Function App configuration"
    $selection = Read-Host "Enter index(es) comma-separated, 'A' for all, or 0 to skip"

    if ($selection -match '^[Aa]$') { return $names }
    if ($selection.Trim() -eq '0') {
        Log-Message "Skipping Function App configuration (user chose to skip)." -Level "WARNING"
        return @()
    }

    $picked = @()
    foreach ($tok in ($selection -split ',')) {
        $idx = ($tok.Trim()) -as [int]
        if ($null -ne $idx -and $idx -ge 1 -and $idx -le $names.Count) {
            $picked += $names[$idx - 1]
        }
    }
    $picked = @($picked | Select-Object -Unique)
    if ($picked.Count -eq 0) {
        Log-Message "No valid Function Apps selected; skipping." -Level "WARNING"
    }
    else {
        Log-Message "Selected Function App(s): $($picked -join ', ')"
    }
    return $picked
}

function Configure-FunctionAppIdentity {
    param(
        [Parameter(Mandatory = $true)][string] $ResourceGroupName,
        [Parameter(Mandatory = $true)][hashtable] $Identity,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]] $FunctionApps
    )
    Write-Host "------------------------------------------------------------------------"
    if (-not $FunctionApps -or $FunctionApps.Count -eq 0) {
        Log-Message "Skipping Function App identity configuration (no apps selected)." -Level "WARNING"
        return
    }
    if ([string]::IsNullOrWhiteSpace($Identity.ResourceId)) {
        Log-Message "Cannot attach identity: managed identity resource id is unknown. Re-run with -IdentityName so it can be resolved." -Level "ERROR"
        return
    }

    foreach ($app in $FunctionApps) {
        Log-Message "Configuring Function App ""$app""..."
        try {
            # 1) Attach the user-assigned managed identity to the Function App.
            az functionapp identity assign --name $app --resource-group $ResourceGroupName --identities $Identity.ResourceId --output none
            if ($LASTEXITCODE -eq 0) {
                Log-Message "  Managed identity attached to ""$app""."
            }
            else {
                Log-Message "  Failed to attach identity to ""$app""." -Level "WARNING"
            }

            # 2) Set AZURE_CLIENT_ID so DefaultAzureCredential selects this identity.
            # Use `az webapp config appsettings set` (not `az functionapp ...`): the functionapp
            # path calls check_language_runtime and crashes with "'NoneType' object has no
            # attribute 'lower'" when the app has no language runtime (custom-container / Java).
            # Function Apps are App Service resources; webapp settings apply the same way.
            if (-not $SkipSetAzureClientId) {
                if ([string]::IsNullOrWhiteSpace($Identity.ClientId)) {
                    Log-Message "  AZURE_CLIENT_ID not set: identity client id is unknown." -Level "WARNING"
                }
                else {
                    az webapp config appsettings set --name $app --resource-group $ResourceGroupName --settings "AZURE_CLIENT_ID=$($Identity.ClientId)" --output none
                    if ($LASTEXITCODE -eq 0) {
                        Log-Message "  AZURE_CLIENT_ID set to $($Identity.ClientId)."
                    }
                    else {
                        Log-Message "  Failed to set AZURE_CLIENT_ID on ""$app""." -Level "WARNING"
                    }
                }
            }
            else {
                Log-Message "  Skipping AZURE_CLIENT_ID (per -SkipSetAzureClientId)."
            }

            # 3) Restart so the attached identity / new app setting takes effect.
            if (-not $SkipRestart) {
                az functionapp restart --name $app --resource-group $ResourceGroupName --output none
                if ($LASTEXITCODE -eq 0) {
                    Log-Message "  Restarted ""$app""."
                }
                else {
                    Log-Message "  Failed to restart ""$app""; restart it manually." -Level "WARNING"
                }
            }
            else {
                Log-Message "  Skipping restart (per -SkipRestart); restart the app during your deploy window."
            }
        }
        catch {
            Log-Message "Function App configuration failed for ""$app"": $($_.Exception.Message)" -Level "ERROR"
        }
    }
}

Write-Host "Logging to file $logFilePath"

Log-Message "------------------------------------ Starting AAD auth configuration ------------------------------------"

$selectedSubscriptionId = Select-AzureSubscription
if (-not $selectedSubscriptionId) {
    Log-Message "Login to Azure failed. Exiting" -Level "ERROR"
    exit 1
}

$resourceGroupRes = Select-ResourceGroup -SubscriptionId $selectedSubscriptionId
if (-not $resourceGroupRes) {
    Log-Message "Failed to retrieve the resource group." -Level "ERROR"
    exit 1
}

$identity = Resolve-ManagedIdentity -ResourceGroupName $resourceGroupRes

$cosmosAccount = Select-CosmosAccount -ResourceGroupName $resourceGroupRes
$storageAccount = Select-StorageAccount -ResourceGroupName $resourceGroupRes
$serviceBusNs = Select-ServiceBusNamespace -ResourceGroupName $resourceGroupRes
$mysqlServer = Select-MySqlServer -ResourceGroupName $resourceGroupRes
$functionApps = Select-FunctionApps -ResourceGroupName $resourceGroupRes

# Grant data-plane access first, then attach the identity to the apps and restart.
Configure-CosmosAadAuth -ResourceGroupName $resourceGroupRes -Identity $identity -AccountName $cosmosAccount
Configure-StorageAadAuth -ResourceGroupName $resourceGroupRes -Identity $identity -AccountName $storageAccount
Configure-ServiceBusAadAuth -ResourceGroupName $resourceGroupRes -Identity $identity -NamespaceName $serviceBusNs
Configure-MySqlAadAuth -ResourceGroupName $resourceGroupRes -Identity $identity -ServerName $mysqlServer
Configure-FunctionAppIdentity -ResourceGroupName $resourceGroupRes -Identity $identity -FunctionApps $functionApps

Log-Message "Set the application flags to activate AAD auth:"
Write-Host "    cosmos_useaadauth: ""true""   (azure section of appconfig)"
Write-Host "    useAadAuth: true             (dbserver.primary of appconfig)"

Log-Message "------------------------------------ Finished AAD auth configuration ------------------------------------"
