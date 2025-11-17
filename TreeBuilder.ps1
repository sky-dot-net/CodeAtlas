<#
.SYNOPSIS
Builds recursive tree structure from file list

.DESCRIPTION
Converts flat file list into hierarchical tree for treemap visualization
#>

function New-TreeNode {
    param([string]$Name)
    
    return @{
        name     = $Name
        children = @{}
    }
}

function Add-FileToTree {
    param(
        [hashtable]$Tree,
        [string[]]$PathParts,
        [hashtable]$FileInfo,
        [string]$FullPathSoFar = ""
    )
    
    if ($PathParts.Count -eq 1) {
        # Leaf node - this is the file
        $Tree[$PathParts[0]] = $FileInfo
    }
    else {
        # Branch node - this is a folder
        $folderName = $PathParts[0]
        $currentPath = if ($FullPathSoFar) { "$FullPathSoFar/$folderName" } else { $folderName }
        
        if (-not $Tree.ContainsKey($folderName)) {
            $Tree[$folderName] = @{
                name     = $folderName
                path     = $currentPath
                children = @{}
            }
        }
        
        Add-FileToTree -Tree $Tree[$folderName].children -PathParts $PathParts[1..($PathParts.Count - 1)] -FileInfo $FileInfo -FullPathSoFar $currentPath
    }
}

function Build-FileTree {
    param(
        [array]$Files,
        [string]$RepoRoot,
        [bool]$UseGitPaths
    )
    
    $tree = @{ children = @{} }
    
    foreach ($file in $Files) {
        if ($UseGitPaths) {
            $relativePath = $file
            $fullPath = Join-Path $RepoRoot $file
        }
        else {
            $fullPath = $file.FullName
            $relativePath = $fullPath.Replace("$RepoRoot\", '').Replace('\', '/')
        }
        
        if (-not (Test-Path $fullPath)) { continue }
        
        # Read content
        $content = Get-Content -LiteralPath $fullPath -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        $extension = [System.IO.Path]::GetExtension($fullPath).ToLower()
        
        # Count LOC
        $commentPatterns = Get-CommentPatterns -Extension $extension
        $loc = ($content -split "`n" | Where-Object { 
                $trimmed = $_.Trim()
                if ([string]::IsNullOrWhiteSpace($trimmed)) { return $false }
                foreach ($pattern in $commentPatterns) {
                    if ($trimmed.StartsWith($pattern)) { return $false }
                }
                return $true
            }).Count
        
        if ($loc -eq 0) { continue }
        
        # Get code blocks
        $blocks = Get-CodeBlocks -FilePath $fullPath -Content $content
        
        # Build file info
        $fileName = Split-Path $relativePath -Leaf
        $fileInfo = @{
            name   = $fileName
            loc    = $loc
            path   = $relativePath
            blocks = $blocks
            isFile = $true
        }
        
        # Add to tree
        $pathParts = $relativePath -split '/'
        Add-FileToTree -Tree $tree.children -PathParts $pathParts -FileInfo $fileInfo
    }
    
    return $tree
}
