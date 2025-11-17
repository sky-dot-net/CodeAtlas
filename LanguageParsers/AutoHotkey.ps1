<#
.SYNOPSIS
AutoHotkey language parser for LOC treemap

.DESCRIPTION
Parses AutoHotkey files to extract code blocks (functions, labels, hotkeys)

.EXTENSIONS
.ahk,.ahk2
#>

function Get-AutoHotkeyBlocks {
    param([string]$FilePath, [string]$Content)
    
    . "$PSScriptRoot\BlockHelpers.ps1"
    
    $blocks = @()
    $lines = $Content -split "`n"
    
    # Functions (FunctionName() {)
    $functionPattern = '^\s*(\w+)\s*\([^)]*\)\s*\{'
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $functionPattern) {
            $functionName = $Matches[1]
            $braceCount = 0
            $functionLines = 0
            
            for ($j = $i; $j -lt $lines.Count; $j++) {
                $line = $lines[$j]
                $braceCount += ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
                $braceCount -= ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
                
                $trimmed = $line.Trim()
                if (-not [string]::IsNullOrWhiteSpace($trimmed) -and 
                    -not $trimmed.StartsWith(';') -and
                    -not $trimmed.StartsWith('/*')) {
                    $functionLines++
                }
                
                if ($braceCount -eq 0 -and $j -gt $i) {
                    if ($functionLines -gt 1) {
                        $blocks += New-CodeBlock -Type 'Function' -Name $functionName -LOC $functionLines -Line ($i + 1)
                    }
                    break
                }
            }
        }
    }
    
    # Hotkeys (^!a::, ::btw::)
    $hotkeyPattern = '^\s*([:^!+#<>*~$]+\w+|[\w]+)::'
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $hotkeyPattern) {
            $hotkeyName = $Matches[1]
            $hotkeyLines = 0
            
            # Count lines until next empty line, return, or next hotkey
            for ($j = $i; $j -lt $lines.Count; $j++) {
                $line = $lines[$j]
                $trimmed = $line.Trim()
                
                # Stop at next hotkey or label
                if ($j -gt $i -and ($trimmed -match '^\w+::' -or $trimmed -match '^\w+:$')) {
                    break
                }
                
                # Stop at return
                if ($trimmed -match '^\s*return\s*$') {
                    if (-not [string]::IsNullOrWhiteSpace($trimmed) -and 
                        -not $trimmed.StartsWith(';')) {
                        $hotkeyLines++
                    }
                    break
                }
                
                if (-not [string]::IsNullOrWhiteSpace($trimmed) -and 
                    -not $trimmed.StartsWith(';') -and
                    -not $trimmed.StartsWith('/*')) {
                    $hotkeyLines++
                }
            }
            
            if ($hotkeyLines -gt 1) {
                $blocks += New-CodeBlock -Type 'Hotkey' -Name "$hotkeyName::" -LOC $hotkeyLines -Line ($i + 1)
            }
        }
    }
    
    # Labels (LabelName:)
    $labelPattern = '^\s*(\w+):\s*$'
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $labelPattern -and $lines[$i] -notmatch '::') {
            $labelName = $Matches[1]
            $labelLines = 0
            
            # Count lines until next label or return
            for ($j = $i; $j -lt $lines.Count; $j++) {
                $line = $lines[$j]
                $trimmed = $line.Trim()
                
                # Stop at next label
                if ($j -gt $i -and ($trimmed -match '^\w+:$' -or $trimmed -match '^\w+::')) {
                    break
                }
                
                # Stop at return
                if ($trimmed -match '^\s*return\s*$') {
                    if (-not [string]::IsNullOrWhiteSpace($trimmed) -and 
                        -not $trimmed.StartsWith(';')) {
                        $labelLines++
                    }
                    break
                }
                
                if (-not [string]::IsNullOrWhiteSpace($trimmed) -and 
                    -not $trimmed.StartsWith(';') -and
                    -not $trimmed.StartsWith('/*')) {
                    $labelLines++
                }
            }
            
            if ($labelLines -gt 1) {
                $blocks += New-CodeBlock -Type 'Label' -Name "${labelName}:" -LOC $labelLines -Line ($i + 1)
            }
        }
    }
    
    return $blocks
}

function Get-AutoHotkeyCommentPatterns {
    return @(';', '/*', '*')
}
