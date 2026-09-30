# Installs stubs and the Explorer image verb from this clone. No admin rights needed.
param(
    [switch]$SkipDeps,
    [string]$ToolsDir = 'C:\dev\tools',
    [switch]$NoPath
)
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne 'Win32NT') {
    throw 'install.ps1 requires Windows. On macOS use bash install.sh.'
}
$RepoDir = $PSScriptRoot
. (Join-Path $RepoDir 'install-lib.ps1')
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null

# Match the original stub: EXEDIR points to the large optional binary, not source.
Write-BatStub 'img-upscale' @"
@echo off
set "EXEDIR=%~dp0"
call "$RepoDir\img-upscale.bat" %*
"@ $ToolsDir

$machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$onPath = (($machinePath -split ';') + ($userPath -split ';')) |
    Where-Object { $_.TrimEnd('\') -ieq $ToolsDir.TrimEnd('\') }
if (-not $onPath -and -not $NoPath) {
    $answer = Read-Host "Add '$ToolsDir' to your User PATH? [Y/n]"
    if ($answer -eq '' -or $answer -imatch '^y') {
        $newPath = (($userPath -join '').TrimEnd(';') + ";$ToolsDir").TrimStart(';')
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        $env:PATH += ";$ToolsDir"
    }
}

$iconsOut = Join-Path $env:LOCALAPPDATA 'img-upscale\icons'
New-Item -ItemType Directory -Path $iconsOut -Force | Out-Null
$pictureIco = Join-Path $iconsOut 'picture.ico'
ConvertTo-Ico (Join-Path $RepoDir 'icons\picture.png') $pictureIco
$command = 'cmd.exe /k ""{0}\img-upscale.bat" "%1""' -f $ToolsDir.TrimEnd('\')
foreach ($ext in $ImageExtensions) {
    $root = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\MikesTools"
    Set-MikesToolsRoot $root
    Add-MikesVerb $root $pictureIco $command
}

if (-not $SkipDeps) {
    & (Join-Path $RepoDir 'deps.ps1')
}
Write-Host "Installed img-upscale from $RepoDir. Open a new terminal to use it." -ForegroundColor Green
