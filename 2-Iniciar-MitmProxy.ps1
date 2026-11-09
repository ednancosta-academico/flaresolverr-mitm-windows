# Inicia apenas o MITM Proxy (Porta 8080) em segundo plano
$ErrorActionPreference = "SilentlyContinue"
$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$MitmDir = Join-Path $BaseDir "mitm"
$MitmExe = Join-Path $MitmDir "venv\Scripts\mitmdump.exe"
$LogDir = Join-Path $BaseDir "logs"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$mitmListening = Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue
if (-not $mitmListening) {
    Write-Host "Iniciando MITM Proxy na porta 8080..." -ForegroundColor Cyan
    Start-Process -FilePath $MitmExe `
        -ArgumentList "-s", "mitm.py", "-p", "8080" `
        -WorkingDirectory $MitmDir `
        -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $LogDir "mitm.log") `
        -RedirectStandardError (Join-Path $LogDir "mitm-err.log")
} else {
    Write-Host "MITM Proxy ja esta rodando na porta 8080." -ForegroundColor Green
}
