# FlareSolverr + MITM Proxy (Nativo no Windows)

Ambiente unificado para rodar o **FlareSolverr** (porta `8191`) e o **flaresolverr-mitm-proxy** (porta `8080`) de forma nativa no Windows (sem necessidade de Docker), organizado na pasta `C:\FlareSolverr`.

Ideal para uso com o plugin [Jellyfin.Plugin.Crunchyroll](https://github.com/Divi-0/Jellyfin.Plugin.Crunchyroll) e automações locais.

---

## Instalação Rápida (Pós-Formatação)

Caso você formate o computador, basta abrir o **PowerShell** e colar o bloco abaixo. Ele baixa o repositório, instala o Python 3.12 (se necessário), baixa a versão mais recente do FlareSolverr direto do GitHub oficial, configura o ambiente virtual do MITM Proxy (já com a correção do idioma `pt-BR`), cria os 3 inicializadores em `C:\FlareSolverr` e ativa a inicialização automática com o Windows:

```powershell
$tempRepo = "$env:TEMP\flaresolverr-mitm-windows"
if (Test-Path $tempRepo) { Remove-Item $tempRepo -Recurse -Force }
git clone https://github.com/ednancosta-academico/flaresolverr-mitm-windows.git $tempRepo
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$tempRepo\install.ps1"
```

Se ainda não tiver o `git` instalado após formatar, você também pode rodar este comando único que não depende do Git:

```powershell
$zip = "$env:TEMP\repo.zip"
$ext = "$env:TEMP\flaresolverr-setup"
if (Test-Path $ext) { Remove-Item $ext -Recurse -Force }
Invoke-WebRequest -Uri "https://github.com/ednancosta-academico/flaresolverr-mitm-windows/archive/refs/heads/main.zip" -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $ext -Force
$folder = Get-ChildItem $ext | Select-Object -First 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$($folder.FullName)\install.ps1"
```

---

## Estrutura da Pasta `C:\FlareSolverr`

```text
C:\FlareSolverr\
├── flaresolverr\                 # Binários do FlareSolverr (porta 8191)
├── mitm\                         # MITM Proxy + ambiente virtual Python (porta 8080)
│   ├── venv\
│   ├── mitm.py
│   └── requirements.txt
├── logs\                         # Logs de execução em segundo plano
├── 1-Iniciar-FlareSolverr.bat    # Inicia apenas o FlareSolverr (duplo clique)
├── 1-Iniciar-FlareSolverr.ps1    # Inicia apenas o FlareSolverr (PowerShell)
├── 2-Iniciar-MitmProxy.bat       # Inicia apenas o MITM Proxy (duplo clique)
├── 2-Iniciar-MitmProxy.ps1       # Inicia apenas o MITM Proxy (PowerShell)
├── 3-Iniciar-Ambos.bat           # Inicia os 2 ao mesmo tempo (duplo clique)
└── 3-Iniciar-Ambos.ps1           # Inicia os 2 ao mesmo tempo (PowerShell)
```

---

## Instalação ou Atualização Manual (Passo a Passo)

Se preferir realizar ou atualizar algum componente manualmente via PowerShell:

### 1. Instalar / Atualizar o FlareSolverr para a versão mais recente

- **Link oficial de releases**: https://github.com/FlareSolverr/FlareSolverr/releases/latest

```powershell
# Para atualizar o FlareSolverr automaticamente para a última versão:
Get-Process -Name "flaresolverr", "chromedriver" -ErrorAction SilentlyContinue | Stop-Process -Force
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/FlareSolverr/FlareSolverr/releases/latest"
$asset = $release.assets | Where-Object { $_.name -like "*windows*x64.zip" } | Select-Object -First 1
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile "$env:TEMP\flaresolverr.zip"
Expand-Archive -Path "$env:TEMP\flaresolverr.zip" -DestinationPath "$env:TEMP\fs_ext" -Force
Remove-Item "C:\FlareSolverr\flaresolverr\*" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$env:TEMP\fs_ext\flaresolverr\*" -Destination "C:\FlareSolverr\flaresolverr" -Recurse -Force
& "C:\FlareSolverr\1-Iniciar-FlareSolverr.ps1"
```

### 2. Recriar o ambiente do MITM Proxy

- **Repositório original de referência**: https://github.com/Divi-0/flaresolverr-mitm-proxy
- **Nota para Windows**: O arquivo `mitm/requirements.txt` deste repositório já remove a dependência exclusiva de Linux (`mitmproxy_linux`), permitindo que o `pip` instale automaticamente o `mitmproxy-windows` no Windows. Além disso, o `mitm/mitm.py` já inclui a normalização de `locale` (`pt-BR-BR` para `pt-BR`).

```powershell
py -3.12 -m venv "C:\FlareSolverr\mitm\venv"
& "C:\FlareSolverr\mitm\venv\Scripts\pip.exe" install -r "C:\FlareSolverr\mitm\requirements.txt"
& "C:\FlareSolverr\2-Iniciar-MitmProxy.ps1"
```

### 3. Verificar se ambos estão rodando

```powershell
Get-NetTCPConnection -LocalPort 8191, 8080 -State Listen
```

---

## Configuração no Jellyfin (Plugin Crunchyroll)

Nas configurações do plugin Crunchyroll no Jellyfin (`http://localhost:8096`):
- **FlareSolverr URL**: `http://localhost:8191/v1`
- **FlareSolverr Mitm Proxy URL**: `http://localhost:8080`
