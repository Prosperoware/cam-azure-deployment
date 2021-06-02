param(
    [string][Parameter(Mandatory=$true)] $configFunctionUrl,
    [string][Parameter(Mandatory=$true)] $accessKey
)

$null = az rest --method POST --uri "$($configFunctionUrl)?code=$($accessKey)"

