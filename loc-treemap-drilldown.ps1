<#
.SYNOPSIS
Generate interactive drill-down LOC treemap with code block analysis

.PARAMETER Extensions
Comma-separated list of file extensions to include (e.g., ".ps1,.cs")

.PARAMETER ScanEntireRepo
Scan entire repository regardless of git tracking

.PARAMETER Colors
Comma-separated list of 6 hex colors for the heatmap
#>

param(
    [string]$Extensions,
    [bool]$ScanEntireRepo,
    [bool]$IgnoreDotFolders,
    [string]$Colors,
    [Parameter(Mandatory)]
    [string]$WorkspaceRoot
)

# Parse extensions (handle both comma and space-separated)
[string[]]$extensions = ($Extensions -split '[,\s]+').Trim() | Where-Object { $_ }

if ($extensions.Count -eq 0) {
    Write-Error "No file extensions provided"
    exit 1
}

Write-Host "Found $($extensions.Count) language(s): $($extensions -join ', ')" -ForegroundColor Cyan

# Parse colors
$colorPalette = $Colors -split ',' | ForEach-Object { $_.Trim() }
if ($colorPalette.Count -ne 6) {
    Write-Error "Colors parameter must contain exactly 6 hex colors"
    exit 1
}

$repoRoot = $WorkspaceRoot

# Load modules from extension directory (passed via environment or relative to script)
$extensionRoot = Split-Path -Parent $PSCommandPath
. "$extensionRoot\LanguageParsers\LanguageRegistry.ps1"
. "$extensionRoot\TreeBuilder.ps1"
. "$extensionRoot\TreemapRenderer.ps1"

# Build regex pattern
$extensionPattern = '(' + ($extensions -join '|' -replace '\.', '\.') + ')$'

# Try to get git-tracked files, fallback to filesystem scan
$gitFiles = $null
if (-not $ScanEntireRepo) {
    try {
        $gitFiles = git ls-files 2>&1 | Where-Object { $_ -is [string] -and $_ -match $extensionPattern }
        if ($LASTEXITCODE -ne 0) {
            $gitFiles = $null
        }
        # Filter dot folders if requested
        if ($IgnoreDotFolders -and $gitFiles) {
            $gitFiles = $gitFiles | Where-Object { 
                $pathParts = $_ -split '/'
                -not ($pathParts | Where-Object { $_.StartsWith('.') })
            }
        }
    }
    catch {
        Write-Host "Git not available, scanning filesystem..." -ForegroundColor Yellow
    }
}

if ($gitFiles -and $gitFiles.Count -gt 0) {
    Write-Host "Found $($gitFiles.Count) git-tracked code files" -ForegroundColor Cyan
    $useGit = $true
}
else {
    Write-Host "Scanning all code files in repository..." -ForegroundColor Cyan
    $allFiles = Get-ChildItem -Path $repoRoot -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { 
        $extensions -contains $_.Extension.ToLower() -and
        (-not $IgnoreDotFolders -or $_.FullName -notmatch '[\\\\/]\.')
    }
    Write-Host "Found $($allFiles.Count) code files" -ForegroundColor Cyan
    $useGit = $false
}

# Build tree structure
Write-Host "Building hierarchical tree..." -ForegroundColor Cyan
if ($useGit) {
    $tree = Build-FileTree -Files $gitFiles -RepoRoot $repoRoot -UseGitPaths $true
}
else {
    $tree = Build-FileTree -Files $allFiles -RepoRoot $repoRoot -UseGitPaths $false
}

# Convert to JSON
$json = $tree | ConvertTo-Json -Depth 20 -Compress

# Generate HTML
Write-Host "Generating interactive treemap..." -ForegroundColor Cyan
$templatePath = Join-Path $extensionRoot 'treemap.template.html'
$html = Get-TreemapHTML -JsonData $json -ColorPalette $colorPalette -TemplatePath $templatePath

# Write output to workspace .vscode/LOC-Treemap folder
$extensionDir = Join-Path $repoRoot '.vscode' | Join-Path -ChildPath 'LOC-Treemap'
if (-not (Test-Path $extensionDir)) {
    New-Item -ItemType Directory -Path $extensionDir -Force | Out-Null
}

# Create user parsers directory if it doesn't exist
$userParsersDir = Join-Path $extensionDir 'LanguageParsers'
if (-not (Test-Path $userParsersDir)) {
    New-Item -ItemType Directory -Path $userParsersDir -Force | Out-Null
    
    # Copy template and README for user reference
    $templateSource = Join-Path $extensionRoot 'LanguageParsers' | Join-Path -ChildPath 'TEMPLATE.ps1'
    $readmeContent = @"
# Custom Language Parsers

Place your custom language parser files here (*.ps1).

## How to Create a Parser

1. Copy TEMPLATE.ps1 as a starting point
2. Rename it to YourLanguage.ps1 (e.g., Python.ps1)
3. Add `.EXTENSIONS` metadata (e.g., `.py`)
4. Implement Get-YourLanguageBlocks function
5. Implement Get-YourLanguageCommentPatterns function
6. Reload VS Code and run the treemap command

## Requirements

- Use the shared helper: `New-CodeBlock` for consistent structure
- Each code block must have: Type, Name, LOC, Line (starting line number)
- Comment patterns are used to filter out comment lines when counting LOC

## Example

See TEMPLATE.ps1 for a complete example with documentation.

Bundled parsers (PowerShell, C#, AutoHotkey) are available for reference in the extension installation directory.
"@
    
    if (Test-Path $templateSource) {
        Copy-Item $templateSource -Destination $userParsersDir
    }
    $readmeContent | Out-File -FilePath (Join-Path $userParsersDir 'README.md') -Encoding UTF8
}

# Load user-defined parsers if any exist
$userParserFiles = Get-ChildItem -Path $userParsersDir -Filter '*.ps1' -Exclude 'TEMPLATE.ps1' -ErrorAction SilentlyContinue
if ($userParserFiles) {
    Write-Host "Loading $($userParserFiles.Count) user-defined parser(s)..." -ForegroundColor Cyan
    foreach ($parserFile in $userParserFiles) {
        try {
            . $parserFile.FullName
            Write-Host "  Loaded: $($parserFile.Name)" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Failed to load user parser $($parserFile.Name): $_"
        }
    }
}

$htmlPath = Join-Path $extensionDir 'treemap.html'
$html | Out-File -FilePath $htmlPath -Encoding UTF8

Write-Host "Generated: $htmlPath" -ForegroundColor Green
Write-Host "Click rectangles to drill down through folder hierarchy" -ForegroundColor Yellow
