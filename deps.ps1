# deps.ps1
# Sets up the quality backend (Swin2SR via transformers) and checks the optional
# fast backend (Real-ESRGAN ncnn Vulkan).

$Python = Join-Path $PSScriptRoot '.venv\Scripts\python.exe'
if (-not (Test-Path $Python)) { $Python = 'python' }
if (-not (Get-Command $Python -ErrorAction SilentlyContinue)) {
    throw "Python 3 is required. Install it, add it to PATH and rerun deps.ps1."
}
Write-Host "  [img-upscale] Checking dependencies..." -ForegroundColor Cyan

function Get-PythonImportOutput([string]$Code) {
    # Windows PowerShell can treat a failed import's stderr as a terminating
    # error when the installer uses Stop. A missing module is a normal probe.
    $ErrorActionPreference = 'Continue'
    $result = & $Python -c $Code 2>$null
    if ($LASTEXITCODE -eq 0) { return $result }
}

$requiredPythonPkgs = @(
    @{ module = "numpy"; package = "numpy" }
    @{ module = "PIL"; package = "Pillow" }
    @{ module = "transformers"; package = "transformers" }
    @{ module = "huggingface_hub"; package = "huggingface-hub" }
    @{ module = "safetensors"; package = "safetensors" }
)

$missingPackages = @()
foreach ($pkg in $requiredPythonPkgs) {
    $installed = Get-PythonImportOutput "import $($pkg.module); print('ok')"
    if ($installed -eq "ok") {
        Write-Host "    OK  $($pkg.package)" -ForegroundColor Green
        continue
    }

    $missingPackages += $pkg.package
}

$torchInstalled = Get-PythonImportOutput "import torch; print(torch.__version__)"
if (-not $torchInstalled) {
    Write-Host "    WARNING  torch is not installed" -ForegroundColor Yellow
    Write-Host "    The quality backend needs a working PyTorch install." -ForegroundColor Yellow
    Write-Host "    Run $Python -m pip install torch for CPU support, or install a CUDA build" -ForegroundColor Yellow
    Write-Host "    using https://pytorch.org/get-started/locally/, then rerun deps.ps1." -ForegroundColor Yellow
} else {
    Write-Host "    OK  torch $torchInstalled" -ForegroundColor Green
}

if ($missingPackages.Count -gt 0) {
    Write-Host "    Installing Python packages for the quality backend..." -ForegroundColor Yellow
    & $Python -m pip install $missingPackages
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install one or more Python packages."
    } else {
        Write-Host "    OK  quality backend packages installed" -ForegroundColor Green
    }
}

$exePath = "C:\dev\tools\realesrgan-ncnn-vulkan.exe"
$modelsDir = "C:\dev\tools\models"
$modelParam = Join-Path $modelsDir "realesrgan-x4plus.param"
$modelBin = Join-Path $modelsDir "realesrgan-x4plus.bin"

if (-not (Test-Path $exePath)) {
    Write-Host "    NOTE  fast backend not installed: $exePath" -ForegroundColor Yellow
    Write-Host "    That is fine if you only want the default quality backend." -ForegroundColor Yellow
    return
}

Write-Host "    OK  optional fast backend exe found" -ForegroundColor Green

if ((Test-Path $modelParam) -and (Test-Path $modelBin)) {
    Write-Host "    OK  optional fast backend model files found" -ForegroundColor Green
    return
}

Write-Host "    WARNING  fast backend model files missing under C:\dev\tools\models" -ForegroundColor Yellow
Write-Host "    Expected for the optional fast backend:" -ForegroundColor Yellow
Write-Host "      - C:\dev\tools\models\realesrgan-x4plus.param" -ForegroundColor Yellow
Write-Host "      - C:\dev\tools\models\realesrgan-x4plus.bin" -ForegroundColor Yellow
