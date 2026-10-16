# Retrieves CustomApplication one app at a time. The type fails as a whole with
# UNKNOWN_EXCEPTION, so this isolates the offending app(s) instead of losing all
# 43 of them.
param(
    [string]$Org = 'EG-Sandbox',
    [string]$BackupDir = 'sandbox-backup-20261016'
)

$ErrorActionPreference = 'Continue'
[xml]$part = Get-Content (Join-Path $BackupDir 'parts\CustomApplication.xml')
$version = $part.Package.version
$apps = @($part.Package.types.members)

$partsDir = Join-Path $BackupDir 'parts\CustomApplication-split'
$outRoot  = Join-Path $BackupDir 'metadata\CustomApplication'
New-Item -ItemType Directory -Force -Path $partsDir, $outRoot | Out-Null

$results = @()
foreach ($app in $apps) {
    $safeName = $app -replace '[^A-Za-z0-9_.-]', '_'
    $partXml  = Join-Path $partsDir "$safeName.xml"
    $escaped  = $app -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'

    $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>$escaped</members>
        <name>CustomApplication</name>
    </types>
    <version>$version</version>
</Package>
"@
    [IO.File]::WriteAllText($partXml, $xml, (New-Object Text.UTF8Encoding $false))

    $dest = Join-Path $outRoot $safeName
    New-Item -ItemType Directory -Force -Path $dest | Out-Null

    Write-Host "  $app..." -NoNewline
    $null = sf project retrieve start -o $Org --manifest $partXml `
        --target-metadata-dir $dest --unzip --wait 30 2>&1
    $ok = ($LASTEXITCODE -eq 0)
    Write-Host $(if ($ok) { ' ok' } else { ' FAILED' })
    if (-not $ok) { Remove-Item -Recurse -Force $dest -ErrorAction SilentlyContinue }

    $results += [pscustomobject]@{ Application = $app; Ok = $ok }
}

$results | Export-Csv -NoTypeInformation -Path (Join-Path $BackupDir 'customapplication-summary.csv')
$failed = @($results | Where-Object { -not $_.Ok })
Write-Host ""
Write-Host "apps retrieved: $(@($results | Where-Object Ok).Count) / $($results.Count)"
if ($failed) { Write-Host "failed: $($failed.Application -join ', ')" }
