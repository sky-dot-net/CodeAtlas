<#
.SYNOPSIS
Discovers available languages and their metadata

.DESCRIPTION
Queries the LanguageRegistry to return available languages and extensions
Used by VS Code extension to dynamically discover supported languages
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet('Languages', 'Extensions')]
    [string]$Query,
    
    [Parameter(Mandatory)]
    [string]$RegistryPath
)

# Load registry
if (-not (Test-Path $RegistryPath)) {
    Write-Error "LanguageRegistry.ps1 not found at: $RegistryPath"
    exit 1
}

. $RegistryPath

switch ($Query) {
    'Languages' {
        # Return language metadata
        $languages = $script:LanguageParsers.Values | 
        Select-Object -Unique Language, @{N = 'Extensions'; E = { 
                ($script:LanguageParsers.GetEnumerator() | 
                Where-Object { $_.Value.Language -eq $_.Language } | 
                Select-Object -ExpandProperty Key) -join ','
            }
        } | 
        Sort-Object Language
        
        $languages | ConvertTo-Json -Compress
    }
    
    'Extensions' {
        # Return just the extensions for easy consumption
        $result = @{}
        foreach ($entry in $script:LanguageParsers.GetEnumerator()) {
            $lang = $entry.Value.Language
            if (-not $result.ContainsKey($lang)) {
                $result[$lang] = @()
            }
            $result[$lang] += $entry.Key
        }
        $result | ConvertTo-Json -Compress
    }
}
