# Language Configuration Sync

## Problem
The extension has configuration duplication:
- `package.json` defines language settings manually
- `LanguageParsers/*.ps1` define which extensions each language handles

## Current State
When adding a new language:
1. Create parser file (e.g., `Python.ps1`) with `.EXTENSIONS` metadata
2. **ALSO** manually add to `package.json` under `configuration.properties`

## Ideal State
Only define in parser files; auto-generate `package.json` schema.

## Limitation
VS Code reads `package.json` at **extension install time**, not runtime.
Cannot dynamically generate schema from PowerShell scripts.

## Workaround
This script validates that `package.json` matches discovered languages.

## Usage
```powershell
.\validate-language-config.ps1
```

Returns exit code 0 if synchronized, 1 if mismatch detected.
