param(
  [string]$InstallDir = "D:\CodexBridge",
  [string]$RepoUrl = "https://github.com/Gan-Xing/CodexBridge.git",
  [switch]$SkipServe
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-Command {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  return $null -ne $cmd
}

function Get-NodeMajorVersion {
  if (-not (Test-Command "node")) {
    return 0
  }
  $raw = (& node --version).Trim()
  if ($raw -match "v(\d+)") {
    return [int]$Matches[1]
  }
  return 0
}

function Ensure-CodexConfig {
  $configPath = Join-Path $env:USERPROFILE ".codex\config.toml"
  if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Host "Codex config not found: $configPath" -ForegroundColor Yellow
    return
  }

  $content = Get-Content -LiteralPath $configPath -Raw
  if ($content -match 'service_tier\s*=\s*"default"') {
    $next = $content -replace 'service_tier\s*=\s*"default"', 'service_tier = "fast"'
    Set-Content -LiteralPath $configPath -Value $next -Encoding UTF8
    Write-Host "Fixed Codex service_tier: default -> fast" -ForegroundColor Green
  }
}

function Invoke-ProcessWithTimeout {
  param(
    [string]$FilePath,
    [string[]]$ArgumentList,
    [string]$WorkingDirectory,
    [int]$TimeoutSeconds = 900
  )

  $process = Start-Process `
    -FilePath $FilePath `
    -ArgumentList $ArgumentList `
    -WorkingDirectory $WorkingDirectory `
    -NoNewWindow `
    -PassThru `
    -Wait:$false

  $exited = $process.WaitForExit($TimeoutSeconds * 1000)
  if (-not $exited) {
    Stop-Process -Id $process.Id -Force
    throw "$FilePath timed out after $TimeoutSeconds seconds"
  }
  if ($process.ExitCode -ne 0) {
    throw "$FilePath exited with code $($process.ExitCode)"
  }
}

Write-Step "check local environment"

if (-not (Test-Command "git")) {
  throw "Git is missing. Install Git first: https://git-scm.com/download/win"
}

$nodeMajor = Get-NodeMajorVersion
if ($nodeMajor -lt 24) {
  throw "Node.js 24+ is required. Current major version: $nodeMajor"
}

if (-not (Test-Command "codex")) {
  throw "Codex CLI is missing. Install and login to Codex first."
}

Write-Host "Git OK" -ForegroundColor Green
Write-Host "Node OK: $(& node --version)" -ForegroundColor Green
Write-Host "Codex OK: $(& codex --version)" -ForegroundColor Green

Write-Step "clone or update CodexBridge"

if (Test-Path -LiteralPath $InstallDir) {
  git -C $InstallDir pull --ff-only
} else {
  git clone $RepoUrl $InstallDir
}

Write-Step "install dependencies"
Invoke-ProcessWithTimeout `
  -FilePath "npm" `
  -ArgumentList @("install", "--no-audit", "--no-fund") `
  -WorkingDirectory $InstallDir `
  -TimeoutSeconds 900

Write-Step "fix common Codex config"
Ensure-CodexConfig

Write-Step "patch CodexBridge login timeout handling"
$patchScript = Join-Path $PSScriptRoot "patch-login-timeout.ps1"
if (Test-Path -LiteralPath $patchScript) {
  & powershell -ExecutionPolicy Bypass -File $patchScript -CodexBridgeDir $InstallDir
} else {
  Write-Host "Patch script not found, skip: $patchScript" -ForegroundColor Yellow
}

Write-Step "start WeChat login"
Write-Host "A QR code will be generated. Scan it in WeChat/OpenClaw." -ForegroundColor Yellow
Push-Location $InstallDir
try {
  node node_modules\tsx\dist\cli.mjs src\cli.ts weixin login --timeout-sec 86400
} finally {
  Pop-Location
}

if ($SkipServe) {
  Write-Host "SkipServe is set. Deployment finished without starting bridge." -ForegroundColor Yellow
  exit 0
}

Write-Step "start WeChat bridge"
$serveDir = Join-Path $env:USERPROFILE ".codexbridge\weixin\serve"
New-Item -ItemType Directory -Force -Path $serveDir | Out-Null
$out = Join-Path $serveDir "codexbridge-serve.out.log"
$err = Join-Path $serveDir "codexbridge-serve.err.log"

Start-Process `
  -FilePath "node" `
  -ArgumentList @("node_modules\tsx\dist\cli.mjs", "src\cli.ts", "weixin", "serve", "--cwd", "D:\") `
  -WorkingDirectory $InstallDir `
  -RedirectStandardOutput $out `
  -RedirectStandardError $err `
  -WindowStyle Hidden

Write-Host "Bridge started." -ForegroundColor Green
Write-Host "stdout: $out"
Write-Host "stderr: $err"
Write-Host "Send /h in WeChat to test."
