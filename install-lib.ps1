# Helpers shared by the standalone installer and uninstaller.
$ImageExtensions = @('.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.tif')

function Write-BatStub {
    param([string]$ToolName, [string]$Content, [string]$ToolsDir)
    Set-Content -Path (Join-Path $ToolsDir "$ToolName.bat") -Value $Content -Encoding ASCII
    $bashContent = @'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/__TOOL_NAME__.bat" "$@"
'@.Replace('__TOOL_NAME__', $ToolName)
    Set-Content -Path (Join-Path $ToolsDir $ToolName) -Value $bashContent -Encoding ASCII
}

# PNG-in-ICO preserves the original alpha channel. picture.png is 16x16.
function ConvertTo-Ico($pngPath, $icoPath) {
    $pngBytes = [System.IO.File]::ReadAllBytes($pngPath)
    $stream = [System.IO.FileStream]::new($icoPath, [System.IO.FileMode]::Create)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]1)
        $writer.Write([byte]16); $writer.Write([byte]16); $writer.Write([byte]0)
        $writer.Write([byte]0); $writer.Write([uint16]1); $writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length); $writer.Write([uint32]22)
        $writer.Write($pngBytes)
    } finally {
        $writer.Dispose()
    }
}

function Set-MikesToolsRoot($rootKey) {
    # Do not rewrite an existing shared root or its icon, which another tool owns.
    if (-not (Test-Path $rootKey)) {
        New-Item -Path $rootKey -Force | Out-Null
        Set-ItemProperty -Path $rootKey -Name 'MUIVerb' -Value "Mike's Tools"
        Set-ItemProperty -Path $rootKey -Name 'SubCommands' -Value ''
    }
}

function Add-MikesVerb($rootKey, $icon, $command) {
    $verbKey = "$rootKey\shell\ImgUpscale"
    $cmdKey = "$verbKey\command"
    New-Item -Path $verbKey -Force | Out-Null
    New-Item -Path $cmdKey -Force | Out-Null
    Set-ItemProperty -Path $verbKey -Name 'MUIVerb' -Value 'Upscale Image'
    Set-ItemProperty -Path $verbKey -Name 'Icon' -Value $icon
    Set-ItemProperty -Path $cmdKey -Name '(Default)' -Value $command
}
