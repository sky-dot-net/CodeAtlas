<#
.SYNOPSIS
Shared helper functions for code block extraction

.DESCRIPTION
Common utilities used by all language parsers
#>

function New-CodeBlock {
    <#
    .SYNOPSIS
    Creates a standardized code block object with line number
    
    .PARAMETER Type
    Type of code block (Function, Class, If/Else, etc.)
    
    .PARAMETER Name
    Name or description of the code block
    
    .PARAMETER LOC
    Lines of code count
    
    .PARAMETER Line
    Starting line number in the file
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Type,
        
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [int]$LOC,
        
        [Parameter(Mandatory)]
        [int]$Line
    )
    
    return [PSCustomObject]@{
        Type = $Type
        Name = $Name
        LOC  = $LOC
        Line = $Line
    }
}
