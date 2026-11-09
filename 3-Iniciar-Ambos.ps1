# Inicia o FlareSolverr (8191) e o MITM Proxy (8080) simultaneamente
$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

& (Join-Path $BaseDir "1-Iniciar-FlareSolverr.ps1")
& (Join-Path $BaseDir "2-Iniciar-MitmProxy.ps1")
