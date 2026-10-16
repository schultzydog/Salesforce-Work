# EG-Sandbox backup — 2026-10-16

Taken immediately before refreshing EG-Sandbox from production.

## What's here

| Path | Contents |
| --- | --- |
| `full-package.xml` | Manifest generated from the org: 126 types, 9,217 components |
| `parts/` | Per-type manifests used to retrieve (see note below) |
| `metadata/<Type>/` | Retrieved metadata, one folder per type |
| `data/*.csv` | Record exports |
| `retrieve-summary.csv` | Pass/fail per metadata type |
| `customapplication-summary.csv` | Pass/fail per custom application |

## Coverage

Metadata: **125 of 126 types** retrieved (6,462 files, 35 MB).

- `CustomApplication` failed as a whole type, so it was retrieved app by app: **42 of 43**.
- `standard__Insights` could not be retrieved. It is a stock Salesforce application
  containing nothing specific to this org.

Data:

| Dataset | Rows |
| --- | --- |
| `time-entries` | 11 |
| `time-cards` | 15 |
| `events` | 8 |
| `projects` | 2,006 |
| `project-tasks` | 2,012 |

Time entries and time cards are scoped to the last 120 days plus anything carrying
`Source_Event_Id__c` or `Time_Entry_Source__c`, which covers the Outlook panel and
Event Review test records.

## Why retrieval is split per type

A single retrieve of the full manifest fails with `UNKNOWN_EXCEPTION`, and that
failure discards every other type in the request. `scripts/backup-sandbox-metadata.ps1`
therefore issues one request per type so a bad type costs only that type.

## Reproducing

```powershell
sf project generate manifest --from-org EG-Sandbox --name sandbox-backup-<date>/full-package --output-dir .
powershell -File scripts/backup-sandbox-metadata.ps1 -BackupDir sandbox-backup-<date>
powershell -File scripts/backup-custom-applications.ps1 -BackupDir sandbox-backup-<date>
powershell -File scripts/backup-sandbox-data.ps1 -BackupDir sandbox-backup-<date>/data
```

## Not committed

`Certificate`, `ConnectedApp`, `NamedCredential` and `SamlSsoConfig` are excluded
from git by `.gitignore`. They remain in this folder on disk. Review them before
putting them in a remote repository.
