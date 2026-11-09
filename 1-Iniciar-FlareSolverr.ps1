# Inicia apenas o FlareSolverr (Porta 8191) em segundo plano
$ErrorActionPreference = "SilentlyContinue"
$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FlareExe = Join-Path $BaseDir "flaresolverr\flaresolverr.exe"
$LogDir = Join-Path $BaseDir "logs"

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$flareListening = Get-NetTCPConnection -LocalPort 8191 -State Listen -ErrorAction SilentlyContinue
if (-not $flareListening) {
    Write-Host "Iniciando FlareSolverr na porta 8191..." -ForegroundColor Cyan
    Start-Process -FilePath $FlareExe `
        -WorkingDirectory (Join-Path $BaseDir "flaresolverr") `
        -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $LogDir "flaresolverr.log") `
        -RedirectStandardError (Join-Path $LogDir "flaresolverr-err.log")
} else {
    Write-Host "FlareSolverr ja esta rodando na porta 8191." -ForegroundColor Green
}
