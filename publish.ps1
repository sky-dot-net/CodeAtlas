<#
.SYNOPSIS
Publish VS Code LOC Treemap extension

.DESCRIPTION
Automates building, packaging, and installing the VS Code extension
#>

$extensionPath = $PSScriptRoot
$vsixName = "loc-treemap"

Push-Location $extensionPath

try {
    Write-Host "Publishing LOC Treemap Extension..." -ForegroundColor Cyan
    
    # Rebuild package.json from language parsers
    Write-Host "Rebuilding package.json from language parsers..." -ForegroundColor Yellow
    & "$extensionPath\rebuild-package-json.ps1"
    
    # Clean old VSIX
    Write-Host "Cleaning old packages..." -ForegroundColor Yellow
    Remove-Item "$extensionPath\*.vsix" -Force -ErrorAction SilentlyContinue
    
    # Get current version
    $packageJson = Get-Content "$extensionPath\package.json" | ConvertFrom-Json
    $currentVersion = $packageJson.version
    
    # Increment patch version
    $versionParts = $currentVersion -split '\.'
    $versionParts[2] = [int]$versionParts[2] + 1
    $newVersion = $versionParts -join '.'
    
    # Update package.json with new version
    Write-Host "Bumping version: $currentVersion -> $newVersion" -ForegroundColor Yellow
    $packageJson.version = $newVersion
    $packageJson | ConvertTo-Json -Depth 10 | Set-Content "$extensionPath\package.json"
    
    # Package
    Write-Host "Packaging extension..." -ForegroundColor Yellow
    vsce package --allow-missing-repository --baseContentUrl "https://raw.githubusercontent.com/PLACEHOLDER/CodeAtlas/main/" --baseImagesUrl "https://raw.githubusercontent.com/PLACEHOLDER/CodeAtlas/main/" --skip-license 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        throw "Packaging failed"
    }
    
    $vsixFile = "$extensionPath\$vsixName-$newVersion.vsix"
    
    if (-not (Test-Path $vsixFile)) {
        throw "VSIX file not created"
    }
    
    Write-Host "Package created: $vsixFile" -ForegroundColor Green
    
    # Uninstall old version
    Write-Host "Uninstalling previous version..." -ForegroundColor Yellow
    $installedExtensions = Get-ChildItem "~/.vscode/extensions" | Where-Object { $_.Name -like "local.$vsixName-*" }
    foreach ($ext in $installedExtensions) {
        Remove-Item $ext.FullName -Recurse -Force
        Write-Host "  Removed: $($ext.Name)" -ForegroundColor Gray
    }
    
    # Install new version
    Write-Host "Installing new version..." -ForegroundColor Yellow
    
    # Extract VSIX to extensions folder
    $targetFolder = "$env:USERPROFILE\.vscode\extensions\local.$vsixName-$newVersion"
    
    # VSIX is just a ZIP file
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($vsixFile, $targetFolder)
    
    # Move contents from extension/ subfolder to root
    $extensionSubfolder = Join-Path $targetFolder "extension"
    if (Test-Path $extensionSubfolder) {
        Get-ChildItem $extensionSubfolder | Move-Item -Destination $targetFolder -Force
        Remove-Item $extensionSubfolder -Force
    }
    
    Write-Host "`nExtension published and installed!" -ForegroundColor Green
    Write-Host "Version: $newVersion" -ForegroundColor Cyan
    Write-Host "`nReload VS Code window (Ctrl+Shift+P -> 'Developer: Reload Window') to activate." -ForegroundColor Yellow
    
}
catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}
