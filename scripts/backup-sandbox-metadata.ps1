# Retrieves the org's metadata one type at a time into a dated backup folder.
# A single-shot retrieve of the whole manifest fails with UNKNOWN_EXCEPTION, and
# that failure takes every other type with it, so each type gets its own request
# and its own pass/fail line in the summary.
param(
    [string]$Org = 'EG-Sandbox',
    [string]$BackupDir = 'sandbox-backup-20261016'
)

$ErrorActionPreference = 'Continue'
$manifest = Join-Path $BackupDir 'full-package.xml'
[xml]$pkg = Get-Content $manifest
$version = $pkg.Package.version

$partsDir = Join-Path $BackupDir 'parts'
$outDir   = Join-Path $BackupDir 'metadata'
New-Item -ItemType Directory -Force -Path $partsDir, $outDir | Out-Null

$results = @()

foreach ($type in $pkg.Package.types) {
    $name    = $type.name
    $members = @($type.members)
    $partXml = Join-Path $partsDir "$name.xml"

    $sb = New-Object Text.StringBuilder
    [void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
    [void]$sb.AppendLine('<Package xmlns="http://soap.sforce.com/2006/04/metadata">')
    [void]$sb.AppendLine('    <types>')
    foreach ($m in $members) {
        $safe = $m -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
        [void]$sb.AppendLine("        <members>$safe</members>")
    }
    [void]$sb.AppendLine("        <name>$name</name>")
    [void]$sb.AppendLine('    </types>')
    [void]$sb.AppendLine("    <version>$version</version>")
    [void]$sb.AppendLine('</Package>')
    [IO.File]::WriteAllText($partXml, $sb.ToString(), (New-Object Text.UTF8Encoding $false))

    $dest = Join-Path $outDir $name
    New-Item -ItemType Directory -Force -Path $dest | Out-Null

    Write-Host "retrieving $name ($($members.Count))..." -NoNewline
    $null = sf project retrieve start -o $Org --manifest $partXml `
        --target-metadata-dir $dest --unzip --wait 60 2>&1
    $ok = ($LASTEXITCODE -eq 0)
    Write-Host $(if ($ok) { ' ok' } else { ' FAILED' })

    $results += [pscustomobject]@{ Type = $name; Count = $members.Count; Ok = $ok }
}

$results | Export-Csv -NoTypeInformation -Path (Join-Path $BackupDir 'retrieve-summary.csv')
$failed = @($results | Where-Object { -not $_.Ok })
Write-Host ""
Write-Host "types retrieved: $(@($results | Where-Object Ok).Count) / $($results.Count)"
if ($failed) { Write-Host "failed: $($failed.Type -join ', ')" }
