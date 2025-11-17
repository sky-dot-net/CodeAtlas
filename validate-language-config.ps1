<#
.SYNOPSIS
Validates that package.json language settings match discovered parsers

.DESCRIPTION
Compares language definitions in LanguageParsers/*.ps1 with package.json settings.
Reports any mismatches.
#>

$ErrorActionPreference = 'Stop'

# Load language registry
. "$PSScriptRoot\LanguageParsers\LanguageRegistry.ps1"

# Get discovered languages
$discoveredLanguages = $script:LanguageParsers.Values | 
Select-Object -Unique -ExpandProperty Language |
Sort-Object

# Read package.json
$packageJson = Get-Content "$PSScriptRoot\package.json" -Raw | ConvertFrom-Json

# Get configured languages from package.json
$configuredLanguages = $packageJson.contributes.configuration.properties.PSObject.Properties |
Where-Object { $_.Name -like 'locTreemap.languages.*' } |
ForEach-Object { 
    $_.Name -replace 'locTreemap\.languages\.', '' 
} |
ForEach-Object {
    # Normalize to match parser convention (e.g., powerShell -> PowerShell)
    $script:LanguageParsers.Values | 
    Where-Object { $_.Language.ToLower() -eq $_.ToLower() } |
    Select-Object -First 1 -ExpandProperty Language
} |
Where-Object { $_ } |
Sort-Object -Unique

# Compare
$missing = $discoveredLanguages | Where-Object { $_ -notin $configuredLanguages }
$extra = $configuredLanguages | Where-Object { $_ -notin $discoveredLanguages }

if ($missing -or $extra) {
    Write-Host "❌ Language configuration mismatch detected!" -ForegroundColor Red
    
    if ($missing) {
        Write-Host "`nMissing from package.json:" -ForegroundColor Yellow
        $missing | ForEach-Object { Write-Host "  - $_" }
        Write-Host "`nAdd to package.json:" -ForegroundColor Cyan
        $missing | ForEach-Object {
            $lower = $_.ToLower()
            $exts = ($script:LanguageParsers.GetEnumerator() | 
                Where-Object { $_.Value.Language -eq $_ } | 
                Select-Object -ExpandProperty Key) -join ', '
            Write-Host @"
        "locTreemap.languages.$lower": {
          "type": "boolean",
          "default": false,
          "description": "Include $_ files ($exts)"
        },
"@
        }
    }
    
    if ($extra) {
        Write-Host "`nExtra in package.json (no parser found):" -ForegroundColor Yellow
        $extra | ForEach-Object { Write-Host "  - $_" }
    }
    
    exit 1
}

Write-Host "✅ Language configuration synchronized!" -ForegroundColor Green
Write-Host "Configured languages: $($discoveredLanguages -join ', ')" -ForegroundColor Cyan
exit 0
