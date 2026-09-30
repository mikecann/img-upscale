@echo off
setlocal

if not defined EXEDIR set "EXEDIR=%~dp0"

if exist "%~dp0.venv\Scripts\python.exe" (
    "%~dp0.venv\Scripts\python.exe" "%~dp0img-upscale.py" %*
) else (
    python "%~dp0img-upscale.py" %*
)
