<#
.SYNOPSIS
Template for new language parsers

.DESCRIPTION
Copy this file and implement the two functions below.
The helper function New-CodeBlock ensures consistent structure.

.EXTENSIONS
.ext1,.ext2

.EXAMPLE
# For a new language like Python:
# 1. Copy this to Python.ps1
# 2. Change .EXTENSIONS to .py
# 3. Implement Get-PythonBlocks
# 4. Implement Get-PythonCommentPatterns
# 5. Done! No need to register anywhere - auto-discovered
#>

function Get-<LANGUAGE>Blocks {
    <#
    .SYNOPSIS
    Extracts code blocks from <LANGUAGE> files
    
    .PARAMETER FilePath
    Full path to the file being parsed
    
    .PARAMETER Content
    Raw file content as string
    
    .NOTES
    MUST use New-CodeBlock helper to create blocks with line numbers
    #>
    param([string]$FilePath, [string]$Content)
    
    # Load shared helper
    . "$PSScriptRoot\BlockHelpers.ps1"
    
    $blocks = @()
    
    # TODO: Parse $Content and extract code blocks
    # Example:
    # foreach ($function in $functions) {
    #     $blocks += New-CodeBlock `
    #         -Type 'Function' `
    #         -Name $function.Name `
    #         -LOC $function.LineCount `
    #         -Line $function.StartLine
    # }
    
    return $blocks
}

function Get-<LANGUAGE>CommentPatterns {
    <#
    .SYNOPSIS
    Returns comment prefixes for LOC counting
    
    .NOTES
    Used to filter out comment lines when counting LOC
    #>
    return @(
        '#',        # Single-line comments
        '"""',      # Multi-line comments
        "'''"       # Alternative multi-line
    )
}
