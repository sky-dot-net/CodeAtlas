<#
.SYNOPSIS
PowerShell language parser for LOC treemap

.DESCRIPTION
Parses PowerShell files using AST to extract code blocks

.EXTENSIONS
.ps1,.psm1
#>

function Get-PowerShellBlocks {
    param([string]$FilePath, [string]$Content)
    
    . "$PSScriptRoot\BlockHelpers.ps1"
    
    $blocks = @()
    
    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$null)
        
        # Functions
        $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        foreach ($func in $functions) {
            $loc = ($func.Extent.Text -split "`n" | Where-Object { 
                    $trimmed = $_.Trim()
                    -not [string]::IsNullOrWhiteSpace($trimmed) -and 
                    -not $trimmed.StartsWith('#') 
                }).Count
            
            if ($loc -gt 1) {
                $blocks += New-CodeBlock -Type 'Function' -Name $func.Name -LOC $loc -Line $func.Extent.StartLineNumber
            }
        }
        
        # If/Else blocks
        $ifStatements = $ast.FindAll({ 
                $args[0] -is [System.Management.Automation.Language.IfStatementAst] 
            }, $false)
        
        foreach ($ifStmt in $ifStatements) {
            $loc = ($ifStmt.Extent.Text -split "`n" | Where-Object { 
                    $trimmed = $_.Trim()
                    -not [string]::IsNullOrWhiteSpace($trimmed) -and 
                    -not $trimmed.StartsWith('#') 
                }).Count
            
            if ($loc -gt 1) {
                $blocks += New-CodeBlock -Type 'If/Else' -Name "if (line $($ifStmt.Extent.StartLineNumber))" -LOC $loc -Line $ifStmt.Extent.StartLineNumber
            }
        }
        
        # Try/Catch blocks
        $tryCatches = $ast.FindAll({ 
                $args[0] -is [System.Management.Automation.Language.TryStatementAst] 
            }, $true)
        
        foreach ($tryCatch in $tryCatches) {
            $loc = ($tryCatch.Extent.Text -split "`n" | Where-Object { 
                    $trimmed = $_.Trim()
                    -not [string]::IsNullOrWhiteSpace($trimmed) -and 
                    -not $trimmed.StartsWith('#') 
                }).Count
            
            if ($loc -gt 1) {
                $blocks += New-CodeBlock -Type 'Try/Catch' -Name "try/catch (line $($tryCatch.Extent.StartLineNumber))" -LOC $loc -Line $tryCatch.Extent.StartLineNumber
            }
        }
        
        # Loops
        $loops = $ast.FindAll({ 
                $args[0] -is [System.Management.Automation.Language.LoopStatementAst] 
            }, $true)
        
        foreach ($loop in $loops) {
            $loc = ($loop.Extent.Text -split "`n" | Where-Object { 
                    $trimmed = $_.Trim()
                    -not [string]::IsNullOrWhiteSpace($trimmed) -and 
                    -not $trimmed.StartsWith('#') 
                }).Count
            
            if ($loc -gt 1) {
                $loopType = $loop.GetType().Name -replace 'StatementAst', ''
                $blocks += New-CodeBlock -Type $loopType -Name "$loopType (line $($loop.Extent.StartLineNumber))" -LOC $loc -Line $loop.Extent.StartLineNumber
            }
        }
    }
    catch {
        # Parser error - return empty
    }
    
    return $blocks
}

function Get-PowerShellCommentPatterns {
    return @('#', '<#')
}
