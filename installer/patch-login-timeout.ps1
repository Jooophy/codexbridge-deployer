param(
  [string]$CodexBridgeDir = "D:\CodexBridge"
)

$ErrorActionPreference = "Stop"

$target = Join-Path $CodexBridgeDir "src\platforms\weixin\official\login.ts"
if (-not (Test-Path -LiteralPath $target)) {
  throw "Cannot find CodexBridge login.ts: $target"
}

$content = Get-Content -LiteralPath $target -Raw
if ($content -match "UND_ERR_HEADERS_TIMEOUT") {
  Write-Host "Login timeout patch already present." -ForegroundColor Green
  exit 0
}

$old = @'
    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        await sleep(1000);
        continue;
      }
      throw error;
    }
'@

$new = @'
    } catch (error) {
      const code = typeof error === 'object' && error !== null && 'code' in error
        ? String((error as { code?: unknown }).code ?? '')
        : '';
      if (
        error instanceof Error
        && (error.name === 'AbortError'
          || code === 'ETIMEDOUT'
          || code === 'ECONNRESET'
          || code === 'EAI_AGAIN'
          || code === 'UND_ERR_CONNECT_TIMEOUT'
          || code === 'UND_ERR_HEADERS_TIMEOUT')
      ) {
        await sleep(1000);
        continue;
      }
      throw error;
    }
'@

if (-not $content.Contains($old)) {
  throw "Patch anchor not found. CodexBridge may have changed."
}

$content = $content.Replace($old, $new)
Set-Content -LiteralPath $target -Value $content -Encoding UTF8
Write-Host "Patched login timeout handling: $target" -ForegroundColor Green

