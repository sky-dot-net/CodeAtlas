<#
.SYNOPSIS
C# language parser for LOC treemap

.DESCRIPTION
Parses C# files using regex to extract code blocks

.EXTENSIONS
.cs
#>

function Get-CSharpBlocks {
    param([string]$FilePath, [string]$Content)
    
    . "$PSScriptRoot\BlockHelpers.ps1"
    
    $blocks = @()
    $lines = $Content -split "`n"
    
    # Methods/Functions
    $methodPattern = '^\s*(public|private|protected|internal|static|\s)+(async\s+)?(void|int|string|bool|Task|[\w<>]+)\s+(\w+)\s*\('
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $methodPattern) {
            $methodName = $Matches[4]
            $braceCount = 0
            $methodLines = 0
            
            for ($j = $i; $j -lt $lines.Count; $j++) {
                $line = $lines[$j]
                $braceCount += ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
                $braceCount -= ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
                
                $trimmed = $line.Trim()
                if (-not [string]::IsNullOrWhiteSpace($trimmed) -and 
                    -not $trimmed.StartsWith('//') -and
                    -not $trimmed.StartsWith('/*')) {
                    $methodLines++
                }
                
                if ($braceCount -eq 0 -and $j -gt $i) {
                    if ($methodLines -gt 1) {
                        $blocks += New-CodeBlock -Type 'Method' -Name $methodName -LOC $methodLines -Line ($i + 1)
                    }
                    break
                }
            }
        }
    }
    
    # Classes
    $classPattern = '^\s*(public|private|protected|internal|\s)*(static\s+)?(class|interface|struct)\s+(\w+)'
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $classPattern) {
            $className = $Matches[4]
            $braceCount = 0
            $classLines = 0
            
            for ($j = $i; $j -lt $lines.Count; $j++) {
                $line = $lines[$j]
                $braceCount += ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
                $braceCount -= ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
                
                $trimmed = $line.Trim()
                if (-not [string]::IsNullOrWhiteSpace($trimmed) -and 
                    -not $trimmed.StartsWith('//') -and
                    -not $trimmed.StartsWith('/*')) {
                    $classLines++
                }
                
                if ($braceCount -eq 0 -and $j -gt $i) {
                    if ($classLines -gt 1) {
                        $blocks += New-CodeBlock -Type 'Class' -Name $className -LOC $classLines -Line ($i + 1)
                    }
                    break
                }
            }
        }
    }
    
    return $blocks
}

function Get-CSharpCommentPatterns {
    return @('//', '/*', '*')
}
