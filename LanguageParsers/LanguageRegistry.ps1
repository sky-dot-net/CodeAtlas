<#
.SYNOPSIS
Language parser registry for LOC treemap

.DESCRIPTION
Auto-discovers and loads language parsers from the LanguageParsers directory
#>

# Auto-discover and load all language parsers
$excludeFiles = @('LanguageRegistry.ps1', 'BlockHelpers.ps1', 'TEMPLATE.ps1')
$languageFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | 
    Where-Object { $excludeFiles -notcontains $_.Name }

foreach ($file in $languageFiles) {
    . $file.FullName
}

# Auto-build parser mapping from loaded functions
$script:LanguageParsers = @{}

# Discover all Get-*Blocks functions
$blockFunctions = Get-Command -Name "Get-*Blocks" -CommandType Function -ErrorAction SilentlyContinue

foreach ($func in $blockFunctions) {
    # Extract language name (e.g., Get-PowerShellBlocks -> PowerShell)
    $languageName = $func.Name -replace '^Get-' -replace 'Blocks$'
    
    # Get corresponding comment patterns function
    $commentFunc = "Get-${languageName}CommentPatterns"
    
    # Extract extensions from source file
    $sourceFile = $languageFiles | Where-Object { $_.BaseName -eq $languageName } | Select-Object -First 1
    
    if ($sourceFile) {
        $content = Get-Content $sourceFile.FullName -Raw
        if ($content -match '\.EXTENSIONS\s*\r?\n\s*([^\r\n]+)') {
            $extensionsLine = $Matches[1].Trim()
            $extensions = $extensionsLine -split ',' | ForEach-Object { $_.Trim() }
            
            # Register each extension
            foreach ($ext in $extensions) {
                if ($ext) {
                    $script:LanguageParsers[$ext] = @{
                        BlockParser      = $func.Name
                        CommentPatterns  = $commentFunc
                        Language         = $languageName
                    }
                }
            }
        }
    }
}

function Get-CodeBlocks {
    param([string]$FilePath, [string]$Content)
    
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    if ($script:LanguageParsers.ContainsKey($extension)) {
        $parserName = $script:LanguageParsers[$extension].BlockParser
        return & $parserName -FilePath $FilePath -Content $Content
    }
    
    return @()
}

function Get-CommentPatterns {
    param([string]$Extension)
    
    if ($script:LanguageParsers.ContainsKey($Extension)) {
        $functionName = $script:LanguageParsers[$Extension].CommentPatterns
        return & $functionName
    }
    
    return @('#')  # Fallback
}
