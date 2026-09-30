# Cross-platform checks for Windows installer helpers. No registry writes or Pester required.
$ErrorActionPreference = 'Stop'
$RepoDir = Split-Path -Parent $PSScriptRoot
. (Join-Path $RepoDir 'install-lib.ps1')
$testDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $testDir | Out-Null
try {
    $icoPath = Join-Path $testDir 'picture.ico'
    $pngPath = Join-Path $RepoDir 'icons/picture.png'
    ConvertTo-Ico $pngPath $icoPath
    $bytes = [IO.File]::ReadAllBytes($icoPath)
    $png = [IO.File]::ReadAllBytes($pngPath)
    if ($bytes.Length -ne $png.Length + 22 -or
        [BitConverter]::ToUInt16($bytes, 2) -ne 1 -or
        [BitConverter]::ToUInt32($bytes, 18) -ne 22) {
        throw 'Invalid PNG-in-ICO header.'
    }
    for ($i = 0; $i -lt $png.Length; $i++) {
        if ($bytes[$i + 22] -ne $png[$i]) { throw 'ICO changed PNG payload.' }
    }
    Write-BatStub 'img-upscale' "@echo off`r`ncall `"C:\clone with spaces\img-upscale.bat`" %*" $testDir
    $stub = Get-Content -Raw (Join-Path $testDir 'img-upscale.bat')
    if ($stub -notmatch 'clone with spaces' -or $stub -notmatch '%\*') {
        throw 'Stub lost arguments or clone path.'
    }
    $stubBytes = [IO.File]::ReadAllBytes((Join-Path $testDir 'img-upscale.bat'))
    if (@($stubBytes | Where-Object { $_ -gt 127 }).Count -gt 0) {
        throw 'Stub must be ASCII.'
    }
    $bashStub = Get-Content -Raw (Join-Path $testDir 'img-upscale')
    if (-not $bashStub.Contains('exec "$SCRIPT_DIR/img-upscale.bat" "$@"')) {
        throw 'Git Bash stub lost argument forwarding.'
    }
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}

# Simulate registry keys so shared-menu preservation is verified on macOS too.
$script:keys = @{}
function Test-Path($Path) { return $script:keys.ContainsKey($Path) }
function New-Item($Path, [switch]$Force) {
    if (-not $script:keys.ContainsKey($Path)) { $script:keys[$Path] = @{} }
}
function Set-ItemProperty($Path, $Name, $Value) { $script:keys[$Path][$Name] = $Value }
$root = 'HKCU:\Test\MikesTools'
Set-MikesToolsRoot $root
if ($script:keys[$root]['MUIVerb'] -ne "Mike's Tools" -or
    -not $script:keys[$root].ContainsKey('SubCommands')) {
    throw 'New shared menu root is incomplete.'
}
$script:keys[$root]['Icon'] = 'peer.ico'
$peer = "$root\shell\PeerTool"
$script:keys[$peer] = @{ MUIVerb = 'A different tool' }
Set-MikesToolsRoot $root
Add-MikesVerb $root 'picture.ico' 'cmd.exe /k ""C:\dev\tools\img-upscale.bat" "%1""'
if ($script:keys[$root]['Icon'] -ne 'peer.ico' -or
    $script:keys[$peer]['MUIVerb'] -ne 'A different tool') {
    throw 'Installation changed another tool or the shared menu icon.'
}
if ($script:keys["$root\shell\ImgUpscale"]['MUIVerb'] -ne 'Upscale Image' -or
    $script:keys["$root\shell\ImgUpscale\command"]['(Default)'] -notmatch '%1') {
    throw 'Image menu command is incomplete.'
}
Write-Output 'Installer helper checks passed: ICO, ASCII stubs, forwarding and shared menu preservation.'
