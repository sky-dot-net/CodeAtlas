<#
.SYNOPSIS
Rebuilds package.json language settings from language parsers

.DESCRIPTION
Auto-generates the language configuration section in package.json
by discovering all language parsers and their extensions
#>

$extensionPath = Split-Path -Parent $PSCommandPath
$parsersPath = Join-Path $extensionPath "LanguageParsers"

# Load language registry to discover parsers
. "$parsersPath\LanguageRegistry.ps1"

# Read current package.json
$packageJsonPath = Join-Path $extensionPath "package.json"
$packageJson = Get-Content $packageJsonPath | ConvertFrom-Json

# Build language settings from discovered parsers
$languageSettings = [ordered]@{}

# Group extensions by language
$languageMap = @{}
foreach ($ext in $script:LanguageParsers.Keys) {
    $lang = $script:LanguageParsers[$ext].Language
    if (-not $languageMap.ContainsKey($lang)) {
        $languageMap[$lang] = @()
    }
    $languageMap[$lang] += $ext
}

# Create settings for each language
foreach ($lang in $languageMap.Keys | Sort-Object) {
    $extensions = $languageMap[$lang] -join ', '
    $settingName = "locTreemap.languages.$($lang.ToLower())"
    
    # Default enabled for PowerShell and C#, disabled for others
    $defaultEnabled = $lang -in @('PowerShell', 'CSharp')
    
    $languageSettings[$settingName] = @{
        type        = "boolean"
        default     = $defaultEnabled
        description = "Include $lang files ($extensions)"
    }
}

# Preserve existing non-language settings
$newProperties = [ordered]@{}

# Add language settings
foreach ($key in $languageSettings.Keys) {
    $newProperties[$key] = $languageSettings[$key]
}

# Add other settings (scanEntireRepo, ignoreDotFolders, colors)
foreach ($key in $packageJson.contributes.configuration.properties.PSObject.Properties.Name) {
    if ($key -notlike 'locTreemap.languages.*') {
        $newProperties[$key] = $packageJson.contributes.configuration.properties.$key
    }
}

# Update package.json (only the configuration.properties section)
$packageJson.contributes.configuration.properties = $newProperties

# Write back to file with proper depth to preserve arrays
$json = $packageJson | ConvertTo-Json -Depth 20
$json | Set-Content $packageJsonPath -Encoding UTF8

Write-Host "  Updated package.json with $($languageMap.Count) languages" -ForegroundColor Green
