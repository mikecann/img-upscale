param([string]$ToolsDir = 'C:\dev\tools')
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne 'Win32NT') {
    throw 'uninstall.ps1 requires Windows.'
}
. (Join-Path $PSScriptRoot 'install-lib.ps1')
foreach ($ext in $ImageExtensions) {
    $verb = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools\shell\ImgUpscale"
    if (Test-Path $verb) { Remove-Item -Path $verb -Recurse -Force }
}
foreach ($name in @('img-upscale.bat', 'img-upscale')) {
    $path = Join-Path $ToolsDir $name
    if (Test-Path $path) { Remove-Item -LiteralPath $path -Force }
}
$icon = Join-Path $env:LOCALAPPDATA 'img-upscale\icons\picture.ico'
if (Test-Path $icon) { Remove-Item -LiteralPath $icon -Force }
# Leave the shared submenu, PATH, Python packages and large binaries alone.
Write-Host 'Removed img-upscale stubs, icon and Explorer verbs.' -ForegroundColor Green
