# LOC Treemap Visualizer

Interactive drill-down LOC treemap visualization for code projects.

## Features

- **Hierarchical visualization**: Folders → Files → Code Blocks (functions, classes, etc.)
- **Color-coded by size**: Red (largest) → Orange → Yellow → Green → Blue (smallest)
- **Click to drill down**: Navigate through code structure interactively
- **Ctrl+Click navigation**: Jump directly to files/code in editor
- **Dynamic legend**: Shows LOC ranges for current view
- **Responsive design**: Adapts to window size
- **Multi-language support**: PowerShell, C#, AutoHotkey (extensible)
- **AST-based parsing**: Accurate code block detection with line numbers

## Usage

1. Open any workspace in VS Code
2. Open Command Palette (`Ctrl+Shift+P`)
3. Run command: **LOC: Show LOC Treemap**
4. Click rectangles to drill down
5. Use breadcrumbs to navigate back
6. Ctrl+Click to open files/jump to code

## Requirements

- PowerShell 7+ installed
- VS Code 1.85.0 or higher

## Configuration

All settings are optional. The extension works out-of-the-box with smart defaults.

- `locTreemap.languages.*`: Enable/disable languages (default: PowerShell and C# enabled)
- `locTreemap.scanEntireRepo`: Scan all files vs git-tracked only (default: git-tracked)
- `locTreemap.ignoreDotFolders`: Skip folders starting with `.` (default: true)
- `locTreemap.colors.*`: Customize the 6-color gradient

## Installation

Install from VSIX or publish to marketplace.