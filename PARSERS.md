# Creating Custom Language Parsers

CodeAtlas is extensible - you can add support for any programming language by creating a custom parser.

## Overview

A language parser consists of:
1. **Parser file** (`YourLanguage.ps1`) with metadata and two functions
2. **Auto-discovery** - CodeAtlas finds and loads it automatically
3. **Integration** - Works seamlessly with built-in languages

## Quick Start

### 1. Copy the Template

Navigate to `.vscode/CodeAtlas/LanguageParsers/` in your workspace and copy `TEMPLATE.ps1`:

```powershell
Copy-Item TEMPLATE.ps1 Python.ps1
```

### 2. Add Extension Metadata

Edit the file header:

```powershell
<#
.SYNOPSIS
Python language parser for CodeAtlas

.DESCRIPTION
Parses Python files to extract functions, classes, and methods

.EXTENSIONS
.py
#>
```

**Important**: The `.EXTENSIONS` line must list file extensions (comma-separated for multiple).

### 3. Implement Get-YourLanguageBlocks

This function extracts code blocks from file content:

```powershell
function Get-PythonBlocks {
    param([string]$FilePath, [string]$Content)
    
    # Load shared helper
    . "$PSScriptRoot\BlockHelpers.ps1"
    
    $blocks = @()
    $lines = $Content -split "`n"
    
    # Example: Find functions
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*def\s+(\w+)\s*\(') {
            $funcName = $Matches[1]
            $funcLOC = 0
            
            # Count lines until next definition or dedent
            # ... (your parsing logic here)
            
            $blocks += New-CodeBlock `
                -Type 'Function' `
                -Name $funcName `
                -LOC $funcLOC `
                -Line ($i + 1)
        }
    }
    
    return $blocks
}
```

### 4. Implement Get-YourLanguageCommentPatterns

Return comment prefixes for LOC counting:

```powershell
function Get-PythonCommentPatterns {
    return @('#', '"""', "'''")
}
```

### 5. Reload VS Code

Press `Ctrl+Shift+P` → "Developer: Reload Window"

Your parser is now active!

## Parser Contract

### Required Functions

#### Get-{Language}Blocks
**Parameters:**
- `$FilePath` (string): Full path to the file
- `$Content` (string): Raw file content

**Returns:** Array of code block objects created with `New-CodeBlock`

#### Get-{Language}CommentPatterns
**Parameters:** None

**Returns:** Array of strings (comment prefixes)

### Helper Function: New-CodeBlock

Use this to create blocks with consistent structure:

```powershell
New-CodeBlock `
    -Type 'Function'|'Class'|'Method'|'Custom' `
    -Name 'FunctionName' `
    -LOC 42 `
    -Line 15
```

**Required Properties:**
- `Type`: Block type (Function, Class, Method, or custom)
- `Name`: Display name
- `LOC`: Lines of code in this block
- `Line`: Starting line number (1-indexed)

## Parsing Strategies

### Regex-Based (Simple Languages)

Good for languages with clear patterns:

```powershell
# Match function definitions
if ($line -match '^\s*function\s+(\w+)') {
    $funcName = $Matches[1]
    # Count lines...
}
```

### Brace Counting (C-style Languages)

Track `{` and `}` to find block boundaries:

```powershell
$braceCount = 0
for ($j = $i; $j -lt $lines.Count; $j++) {
    $braceCount += ($lines[$j].ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $braceCount -= ($lines[$j].ToCharArray() | Where-Object { $_ -eq '}' }).Count
    
    if ($braceCount -eq 0 -and $j -gt $i) {
        # Block complete
        break
    }
}
```

### Indentation-Based (Python-style)

Track indentation levels:

```powershell
$funcIndent = ($line -match '^\s*').Matches[0].Value.Length
# Continue while next lines are more indented
```

## Complete Example: Python Parser

```powershell
<#
.SYNOPSIS
Python language parser for CodeAtlas

.DESCRIPTION
Parses Python files to extract functions and classes

.EXTENSIONS
.py
#>

function Get-PythonBlocks {
    param([string]$FilePath, [string]$Content)
    
    . "$PSScriptRoot\BlockHelpers.ps1"
    
    $blocks = @()
    $lines = $Content -split "`n"
    
    # Find functions
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*def\s+(\w+)') {
            $funcName = $Matches[1]
            $baseIndent = ($lines[$i] -match '^(\s*)').Matches[0].Value.Length
            $funcLOC = 1
            
            # Count until dedent
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                $line = $lines[$j].Trim()
                if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
                    continue
                }
                
                $currentIndent = ($lines[$j] -match '^(\s*)').Matches[0].Value.Length
                if ($currentIndent -le $baseIndent) {
                    break
                }
                $funcLOC++
            }
            
            if ($funcLOC -gt 1) {
                $blocks += New-CodeBlock -Type 'Function' -Name $funcName -LOC $funcLOC -Line ($i + 1)
            }
        }
    }
    
    # Find classes (similar logic)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*class\s+(\w+)') {
            $className = $Matches[1]
            # ... (count LOC logic)
            $blocks += New-CodeBlock -Type 'Class' -Name $className -LOC $classLOC -Line ($i + 1)
        }
    }
    
    return $blocks
}

function Get-PythonCommentPatterns {
    return @('#', '"""', "'''", 'r"""', "r'''")
}
```

## Testing Your Parser

### 1. Create a Test File

Place a sample file in your workspace:

```python
# test.py
def hello():
    print("world")

class Example:
    def method(self):
        pass
```

### 2. Run CodeAtlas

Execute the treemap command - your test file should appear with parsed blocks.

### 3. Verify Navigation

Ctrl+Click the function/class blocks - editor should jump to exact line numbers.

## Best Practices

### DO:
✅ Use `New-CodeBlock` helper for consistency
✅ Filter comment lines when counting LOC
✅ Return empty array if no blocks found
✅ Handle edge cases gracefully (empty files, syntax errors)
✅ Test with real-world files from the target language

### DON'T:
❌ Throw exceptions on parse failures (return empty array instead)
❌ Include comment/blank lines in LOC counts
❌ Hardcode paths or assumptions about file structure
❌ Forget the `.EXTENSIONS` metadata

## Troubleshooting

### Parser not loading
- Check file is in `.vscode/CodeAtlas/LanguageParsers/`
- Verify `.EXTENSIONS` line exists in header
- Reload VS Code window
- Check Output → CodeAtlas for load errors

### Blocks not appearing
- Verify function returns array of blocks (not `$null`)
- Check line numbers are 1-indexed
- Ensure LOC > 0 for each block

### Wrong line numbers
- Line numbers must be 1-based (first line = 1)
- Use `$i + 1` when iterating 0-indexed arrays

## Contributing Parsers

Have a parser working well? Share it!

1. Test thoroughly with real-world code
2. Add inline documentation
3. Submit PR to CodeAtlas repository
4. Include example files for testing

## Reference: Built-in Parsers

See the extension installation directory for examples:
- `PowerShell.ps1` - AST-based (most accurate)
- `CSharp.ps1` - Regex + brace counting
- `AutoHotkey.ps1` - Mixed strategies

Location: `~/.vscode/extensions/local.codeatlas-*/LanguageParsers/`

## Need Help?

- [Open an issue](../../issues) with your parser code
- [Discussion forum](../../discussions) for questions
- Check existing parsers for patterns

---

**Happy parsing! 🗺️**
