<#
.SYNOPSIS
This script retrieves configuration values from Azure App Configuration based on provided labels and keys. It generates JavaScript files containing the retrieved values for specified keys.

.DESCRIPTION
The script takes the following parameters:
- connectionString: The connection string for Azure App Configuration. If not provided, it looks for the APP_CONFIG_CONNECTION_STRING environment variable.
- configLabels: Comma-separated labels for configuration values in Azure App Configuration. If not provided, it looks for the APP_CONFIG_LABELS environment variable.
- keys: Comma-separated keys for specific configuration values to retrieve.

The script performs the following steps:
1. Validates the connection string and config labels.
2. Parses config labels and keys.
3. Creates an output folder if it doesn't exist.
4. Fetches values from Azure App Config for each label and specified keys.
5. Generates JavaScript files with the retrieved configuration values.

.PARAMETER connectionString
The connection string for Azure App Configuration.

.PARAMETER configLabels
Comma-separated labels for configuration values in Azure App Configuration.

.PARAMETER keys
Comma-separated keys for specific configuration values to retrieve.

.NOTES
File Name      : Fetch-AppConfig.ps1
Prerequisite   : Azure CLI must be installed for the 'az' command.

.EXAMPLE
.\Fetch-AppConfig.ps1 -configLabels "codewolf.internal.test" -keys "CustomerPortal:ApiBaseUrl,CustomerPortal:AuthClientId,CustomerPortal:AuthClientKey,Keycloak:Authority"
This example retrieves configuration values for the label "codewolf.internal.test" and specific keys related to the CustomerPortal and Keycloak applications.
#>

param (
    [string]$connectionString = $env:APP_CONFIG_CONNECTION_STRING,
    [string]$configLabels = $env:APP_CONFIG_LABELS,
    [string]$keys
)

# Validate Connection String
if (-not $connectionString) {
    Write-Host "Error: Connection string not provided. Use -connectionString parameter or set the APP_CONFIG_CONNECTION_STRING environment variable."
    Exit 1
}

# Validate Config Labels
if (-not $configLabels) {
    Write-Host "Error: Config labels not provided. Use -configLabels parameter or set the APP_CONFIG_LABEL environment variable."
    Exit 1
}

# Parse Config Labels and Keys
$configLabelsArray = $configLabels -split ","
$keysArray = $keys -split ","

# Create output folder if it doesn't exist
$outFolder = "out"
if (-not (Test-Path $outFolder -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $outFolder
}3

# Fetch values from Azure App Config and generate output files
foreach ($label in $configLabelsArray) {
    # Write-Host "Label: $label"
    
    $configValuesRaw = az appconfig kv list --connection-string $connectionString --label $label
    # Write-Host "ConfigValuesRaw: $configValuesRaw"

    $configValues = $configValuesRaw | ConvertFrom-Json

    # Write-Host "ConfigValues: $configValues"

    if ($configValues) {
        $outputFile = Join-Path $outFolder "config-$label.js"
        
        # Build JS content
        $jsContent = "window.CW_APP_CONFIG = {"
        foreach ($config in $configValues) {
            if ($keysArray -contains $config.key) {
                $jsContent += "`"$($config.key)`": `"$($config.value)`", "
            }
        }
        $jsContent = $jsContent.TrimEnd(", ") + "};"

        # Write to output file
        $jsContent | Out-File -FilePath $outputFile -Force

        Write-Host "Output file generated: $outputFile"
    }
    else {
        Write-Host "No configuration values found for label: $label"
    }
}