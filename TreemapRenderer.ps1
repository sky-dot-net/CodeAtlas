<#
.SYNOPSIS
Generates HTML treemap visualization from tree data

.DESCRIPTION
Creates interactive D3.js treemap with recursive drill-down
#>

function Get-TreemapHTML {
    param(
        [string]$JsonData,
        [string[]]$ColorPalette,
        [string]$TemplatePath
    )
    
    # Load template
    $template = Get-Content -Path $TemplatePath -Raw -Encoding UTF8
    
    # Build color palette JavaScript array
    $colorsJs = ($ColorPalette | ForEach-Object { "'$_'" }) -join ', '
    
    # Replace placeholders (match template syntax with spaces)
    $html = $template.Replace('{{ DATA_JSON }}', $JsonData)
    $html = $html.Replace('{{ COLOR_PALETTE }}', $colorsJs)
    
    return $html
}
