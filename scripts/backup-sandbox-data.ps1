# Exports the sandbox records the Outlook/timesheet work depends on. A refresh
# from production replaces this data, so the test Events, their time entries and
# the surrounding time cards are captured here to rebuild the scenarios after.
param(
    [string]$Org = 'EG-Sandbox',
    [string]$BackupDir = 'sandbox-backup-20261016\data'
)

$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

# Field lists come from the org rather than being hardcoded, so the export can
# never fail on a field this project guessed at but the org does not have.
function Get-SelectableFields {
    param([string]$SObject)
    $describe = sf sobject describe -o $Org -s $SObject --json 2>$null | ConvertFrom-Json
    $describe.result.fields |
        Where-Object { $_.type -notin @('address', 'location') } |
        ForEach-Object { $_.name }
}

$objects = [ordered]@{
    'time-entries' = @{ SObject = 'EG_Time_Entry__c';  Where = "Source_Event_Id__c != null OR Time_Entry_Source__c != null OR CreatedDate = LAST_N_DAYS:120" }
    'time-cards'   = @{ SObject = 'EG_Time_Card__c';   Where = "CreatedDate = LAST_N_DAYS:120" }
    'events'       = @{ SObject = 'Event';             Where = "CreatedDate = LAST_N_DAYS:120" }
    'projects'     = @{ SObject = 'EG_Project__c';     Where = $null }
    'project-tasks'= @{ SObject = 'EG_Project_Task__c';Where = $null }
}

$queries = [ordered]@{}
foreach ($key in $objects.Keys) {
    $spec   = $objects[$key]
    $fields = Get-SelectableFields $spec.SObject
    if (-not $fields) { Write-Host "could not describe $($spec.SObject), skipping"; continue }
    $soql = "SELECT $($fields -join ', ') FROM $($spec.SObject)"
    if ($spec.Where) { $soql += " WHERE $($spec.Where)" }
    $queries[$key] = $soql
}

$summary = @()
foreach ($key in $queries.Keys) {
    $file = Join-Path $BackupDir "$key.csv"
    Write-Host "exporting $key..." -NoNewline
    $null = sf data query -o $Org -q $queries[$key] --result-format csv --output-file $file 2>&1
    $ok = ($LASTEXITCODE -eq 0) -and (Test-Path $file)
    $rows = if ($ok) { [Math]::Max(0, (@(Get-Content $file)).Count - 1) } else { 0 }
    Write-Host $(if ($ok) { " ok ($rows rows)" } else { ' FAILED' })
    $summary += [pscustomobject]@{ Dataset = $key; Rows = $rows; Ok = $ok }
}

$summary | Export-Csv -NoTypeInformation -Path (Join-Path $BackupDir 'export-summary.csv')
$summary | Format-Table -AutoSize
