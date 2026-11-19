<#
.SYNOPSIS
  Memanggil endpoint migrasi MySQL -> Firestore secara berurutan.

.DESCRIPTION
  Token ADMIN_HTTP_TOKEN diminta secara tersembunyi dan hanya dikirim melalui
  header. Hasil JSON disimpan di functions/migration-output.local/<project>/
  (diabaikan Git dan upload Functions karena berisi data pribadi santri).

  Urutan: compare -> santri -> asatidz -> payments -> reports.
  Dry-run boleh sekaligus (-Step all). Apply wajib per langkah agar hasil
  setiap langkah ditinjau sebelum langkah berikutnya.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\runLegacyMigration.ps1 -ProjectId al-jauhar-app -Step all

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\runLegacyMigration.ps1 -ProjectId al-jauhar-app -Step santri -Apply
#>
param(
  [Parameter(Mandatory = $true)][string]$ProjectId,
  [ValidateSet('compare', 'santri', 'asatidz', 'payments', 'reports', 'all')]
  [string]$Step = 'all',
  [switch]$Apply,
  # Ambil token dari Secret Manager project (versi terbaru) tanpa
  # menampilkannya; memerlukan login Firebase CLI dengan akses secret.
  [switch]$TokenFromSecretManager,
  # Lewati konfirmasi ketik-ulang project ID saat -Apply.
  [switch]$AssumeYes,
  # Folder berisi export phpMyAdmin JSON: santris.json, users.json,
  # payments.json, nilais.json. Bila diisi, data dikirim lewat POST dan
  # endpoint tidak menghubungi MySQL. Kolom password/token users dibuang.
  [string]$DataDir,
  [string]$Region = 'asia-southeast2'
)

$ErrorActionPreference = 'Stop'

if ($Apply -and $Step -eq 'all') {
  throw 'Apply harus dijalankan per langkah (-Step santri/asatidz/payments/reports).'
}
if ($Apply -and $Step -eq 'compare') {
  throw 'compareSantri hanya membaca data; jalankan tanpa -Apply.'
}

$endpoints = [ordered]@{
  compare  = 'compareSantri'
  santri   = 'importSantri'
  asatidz  = 'importAsatidz'
  payments = 'importPayments'
  reports  = 'importMonthlyReports'
}
$steps = if ($Step -eq 'all') { @($endpoints.Keys) } else { @($Step) }

if ($TokenFromSecretManager) {
  $lines = & firebase functions:secrets:access ADMIN_HTTP_TOKEN --project $ProjectId 2>$null
  if ($LASTEXITCODE -ne 0) {
    throw 'Gagal membaca ADMIN_HTTP_TOKEN dari Secret Manager. Pastikan sudah firebase login.'
  }
  $token = (@($lines) | Where-Object { $_ -and $_.Trim() } | Select-Object -Last 1)
  if ($token) { $token = $token.Trim() }
} else {
  $secure = Read-Host -AsSecureString "ADMIN_HTTP_TOKEN untuk $ProjectId"
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}
if ([string]::IsNullOrWhiteSpace($token)) { throw 'Token kosong.' }

if ($Apply -and -not $AssumeYes) {
  $confirm = Read-Host "MENULIS data langkah '$Step' ke $ProjectId. Ketik ulang project ID untuk lanjut"
  if ($confirm -ne $ProjectId) { throw 'Dibatalkan.' }
}

$bodyBytes = $null
if ($DataDir) {
  $parts = @()
  foreach ($name in @('santris', 'users', 'payments', 'nilais')) {
    $path = Join-Path $DataDir "$name.json"
    if (-not (Test-Path -LiteralPath $path)) { throw "File $path tidak ditemukan." }
    $raw = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    if ($name -eq 'users') {
      $doc = $raw | ConvertFrom-Json
      $rows = $null
      foreach ($item in $doc) {
        if ($item.type -eq 'table') { $rows = $item.data }
      }
      if ($null -eq $rows) { $rows = $doc }
      $clean = @($rows | Select-Object -Property * -ExcludeProperty password, remember_token, email_verified_at)
      $raw = ConvertTo-Json -InputObject $clean -Depth 5 -Compress
    }
    $parts += ('"' + $name + '":' + $raw)
  }
  $bodyText = '{"tables":{' + ($parts -join ',') + '}}'
  $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyText)
  Write-Host "Sumber: file JSON di $DataDir ($([math]::Round($bodyBytes.Length / 1KB)) KB)"
}

$outDir = Join-Path $PSScriptRoot "..\migration-output.local\$ProjectId"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$mode = if ($Apply) { 'apply' } else { 'dryrun' }
$headers = @{ 'x-admin-token' = $token }
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-ErrorBody($errorRecord) {
  $status = ''
  $response = $errorRecord.Exception.Response
  if ($null -ne $response) { $status = "HTTP $([int]$response.StatusCode) " }
  $body = ''
  if ($errorRecord.ErrorDetails -and $errorRecord.ErrorDetails.Message) {
    $body = $errorRecord.ErrorDetails.Message
  } else {
    $body = $errorRecord.Exception.Message
  }
  $hint = ''
  if ($status -eq 'HTTP 401 ') { $hint = ' -> token salah/tidak cocok.' }
  return "$status$body$hint"
}

foreach ($s in $steps) {
  $fn = $endpoints[$s]
  $query = ''
  if ($s -eq 'compare') { $query = '?format=json' }
  elseif ($Apply) { $query = '?apply=true' }
  $uri = "https://$Region-$ProjectId.cloudfunctions.net/$fn$query"
  $file = Join-Path $outDir "$stamp-$s-$mode.json"

  Write-Host ""
  Write-Host "==> $fn ($mode)" -ForegroundColor Cyan
  try {
    if ($bodyBytes) {
      $resp = Invoke-WebRequest -Uri $uri -Headers $headers -Method Post `
        -Body $bodyBytes -ContentType 'application/json; charset=utf-8' `
        -UseBasicParsing -TimeoutSec 600
    } else {
      $resp = Invoke-WebRequest -Uri $uri -Headers $headers -Method Get `
        -UseBasicParsing -TimeoutSec 600
    }
    [System.IO.File]::WriteAllText($file, $resp.Content, $utf8)
    $json = $resp.Content | ConvertFrom-Json
    $json.summary | Format-List | Out-String | Write-Host
    Write-Host "Detail: $file"
  } catch {
    $body = Read-ErrorBody $_
    [System.IO.File]::WriteAllText($file, [string]$body, $utf8)
    Write-Host "GAGAL: $body" -ForegroundColor Red
    Write-Host "Detail: $file"
    break
  }
}

$token = $null
