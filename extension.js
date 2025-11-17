const vscode = require('vscode');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');

function activate(context) {
    console.log('LOC Treemap extension is now active!');

    let disposable = vscode.commands.registerCommand('loc-treemap.show', async function () {
        vscode.window.showInformationMessage('LOC Treemap command executed!');

        const workspaceFolders = vscode.workspace.workspaceFolders;
        if (!workspaceFolders) {
            vscode.window.showErrorMessage('No workspace folder open');
            return;
        }

        const workspaceRoot = workspaceFolders[0].uri.fsPath;

        // Get settings
        const config = vscode.workspace.getConfiguration('locTreemap');
        const scanEntireRepo = config.get('scanEntireRepo', false);
        const ignoreDotFolders = config.get('ignoreDotFolders', true);
        const colors = [
            config.get('colors.color1', '#d73a49'),
            config.get('colors.color2', '#ff8c00'),
            config.get('colors.color3', '#ffd700'),
            config.get('colors.color4', '#32cd32'),
            config.get('colors.color5', '#4169e1'),
            config.get('colors.color6', '#00008b')
        ];

        // Use extension's bundled scripts
        const extensionPath = context.extensionPath;
        const scriptPath = path.join(extensionPath, 'loc-treemap-drilldown.ps1');
        const htmlPath = path.join(workspaceRoot, '.vscode', 'LOC-Treemap', 'treemap.html');
        const discoveryScript = path.join(extensionPath, 'discover-languages.ps1');
        const registryPath = path.join(extensionPath, 'LanguageParsers', 'LanguageRegistry.ps1');

        exec(`pwsh -ExecutionPolicy Bypass -File "${discoveryScript}" -Query Extensions -RegistryPath "${registryPath}"`, { cwd: workspaceRoot }, (error, stdout, stderr) => {
            if (error) {
                vscode.window.showErrorMessage(`Failed to discover languages: ${error.message}`);
                console.error(stderr);
                return;
            }

            let languageExtensions;
            try {
                languageExtensions = JSON.parse(stdout.trim());
            } catch (e) {
                vscode.window.showErrorMessage('Failed to parse language discovery result');
                return;
            }

            // Build extensions list from enabled languages in settings
            const extensions = [];
            for (const [language, exts] of Object.entries(languageExtensions)) {
                const settingKey = `languages.${language.toLowerCase()}`;
                const isEnabled = config.get(settingKey, language === 'PowerShell' || language === 'CSharp');

                if (isEnabled) {
                    extensions.push(...exts);
                }
            }

            if (extensions.length === 0) {
                vscode.window.showErrorMessage('No languages selected. Enable at least one language in settings.');
                return;
            }

            executeTreemapGeneration(workspaceRoot, scriptPath, htmlPath, extensions, scanEntireRepo, ignoreDotFolders, colors, context);
        });
    });

    context.subscriptions.push(disposable);
}

function executeTreemapGeneration(workspaceRoot, scriptPath, htmlPath, extensions, scanEntireRepo, ignoreDotFolders, colors, context) {
    // Build arguments
    const args = [];
    args.push(`-WorkspaceRoot "${workspaceRoot}"`);
    args.push(`-Extensions "${extensions.join(',')}"`);
    args.push(`-ScanEntireRepo:$${scanEntireRepo}`);
    args.push(`-IgnoreDotFolders:$${ignoreDotFolders}`);
    args.push(`-Colors "${colors.join(',')}"`);

    vscode.window.showInformationMessage('Generating LOC treemap...');

    // Run PowerShell script with arguments
    const command = `pwsh -ExecutionPolicy Bypass -File "${scriptPath}" ${args.join(' ')}`;
    exec(command, { cwd: workspaceRoot }, (error, stdout, stderr) => {
        if (error) {
            vscode.window.showErrorMessage(`Failed to generate treemap: ${error.message}\n\nCommand: ${command}\n\nError output:\n${stderr}`);
            console.error('STDOUT:', stdout);
            console.error('STDERR:', stderr);
            console.error('Error:', error);
            return;
        }

        if (!fs.existsSync(htmlPath)) {
            vscode.window.showErrorMessage(`HTML treemap was not generated.\n\nExpected at: ${htmlPath}\n\nScript output:\n${stdout}\n\nErrors:\n${stderr}`);
            console.log('Script output:', stdout);
            console.error('Script errors:', stderr);
            return;
        }

        // Read generated HTML
        const htmlContent = fs.readFileSync(htmlPath, 'utf8');

        // Create webview panel
        const panel = vscode.window.createWebviewPanel(
            'locTreemap',
            'LOC Treemap',
            vscode.ViewColumn.One,
            {
                enableScripts: true,
                retainContextWhenHidden: true
            }
        );

        // Handle messages from webview
        panel.webview.onDidReceiveMessage(
            message => {
                switch (message.command) {
                    case 'openFile':
                        const filePath = path.join(workspaceRoot, message.path);
                        const fileUri = vscode.Uri.file(filePath);
                        const line = message.line || 1;
                        vscode.window.showTextDocument(fileUri, {
                            preview: false,
                            selection: new vscode.Range(line - 1, 0, line - 1, 0)
                        });
                        break;
                    case 'revealInExplorer':
                        const folderPath = path.join(workspaceRoot, message.path);
                        const folderUri = vscode.Uri.file(folderPath);
                        vscode.commands.executeCommand('revealInExplorer', folderUri);
                        break;
                }
            },
            undefined,
            context.subscriptions
        );

        // Set HTML content
        panel.webview.html = htmlContent;
    });
}

function deactivate() { }

module.exports = {
    activate,
    deactivate
};
