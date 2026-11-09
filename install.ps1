# Script de instalacao automatica do FlareSolverr + MITM Proxy (Nativo no Windows)
$ErrorActionPreference = "Stop"
$TargetDir = "C:\FlareSolverr"
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "=== Iniciando instalacao do FlareSolverr + MITM Proxy em $TargetDir ===" -ForegroundColor Cyan

# 1. Verificar Python 3.12
$pyCheck = Get-Command py -ErrorAction SilentlyContinue
if (-not $pyCheck) {
    Write-Host "Python nao encontrado. Instalando Python 3.12 via winget..." -ForegroundColor Yellow
    winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
}

# 2. Encerrar processos existentes caso estejam rodando
Get-Process -Name "flaresolverr", "mitmdump", "chromedriver" -ErrorAction SilentlyContinue | Stop-Process -Force

# 3. Criar estrutura de pastas em C:\FlareSolverr
New-Item -ItemType Directory -Path "$TargetDir\flaresolverr" -Force | Out-Null
New-Item -ItemType Directory -Path "$TargetDir\mitm" -Force | Out-Null
New-Item -ItemType Directory -Path "$TargetDir\logs" -Force | Out-Null

# 4. Baixar a versao mais recente do FlareSolverr direto do GitHub
Write-Host "Buscando ultima versao do FlareSolverr no GitHub..." -ForegroundColor Cyan
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/FlareSolverr/FlareSolverr/releases/latest"
$asset = $release.assets | Where-Object { $_.name -like "*windows*x64.zip" } | Select-Object -First 1
Write-Host "Baixando FlareSolverr $($release.tag_name) ($($asset.browser_download_url))..." -ForegroundColor Cyan

$zipPath = "$env:TEMP\flaresolverr_latest.zip"
$extractPath = "$env:TEMP\flaresolverr_extract"
if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }

Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
Copy-Item -Path "$extractPath\flaresolverr\*" -Destination "$TargetDir\flaresolverr" -Recurse -Force
Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue

# 5. Configurar o MITM Proxy e criar ambiente virtual Python (venv)
Write-Host "Configurando MITM Proxy em $TargetDir\mitm..." -ForegroundColor Cyan
Copy-Item -Path "$RepoDir\mitm\mitm.py" -Destination "$TargetDir\mitm\mitm.py" -Force
Copy-Item -Path "$RepoDir\mitm\requirements.txt" -Destination "$TargetDir\mitm\requirements.txt" -Force

if (-not (Test-Path "$TargetDir\mitm\venv\Scripts\python.exe")) {
    py -3.12 -m venv "$TargetDir\mitm\venv"
}
& "$TargetDir\mitm\venv\Scripts\pip.exe" install -r "$TargetDir\mitm\requirements.txt"

# 6. Copiar os 3 inicializadores para a raiz de C:\FlareSolverr
Copy-Item -Path "$RepoDir\1-Iniciar-FlareSolverr.*" -Destination $TargetDir -Force
Copy-Item -Path "$RepoDir\2-Iniciar-MitmProxy.*" -Destination $TargetDir -Force
Copy-Item -Path "$RepoDir\3-Iniciar-Ambos.*" -Destination $TargetDir -Force

# 7. Configurar inicializacao automatica silenciosa com o Windows (shell:startup)
$startupVbs = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\Start-Crunchyroll-Deps.vbs"
$vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\FlareSolverr\3-Iniciar-Ambos.ps1""", 0, False
"@
Set-Content -Path $startupVbs -Value $vbsContent -Encoding ASCII

# 8. Iniciar ambos os servicos
Write-Host "Iniciando FlareSolverr (8191) e MITM Proxy (8080)..." -ForegroundColor Cyan
& "$TargetDir\3-Iniciar-Ambos.ps1"

Write-Host "=== Instalacao concluida com sucesso! ===" -ForegroundColor Green
