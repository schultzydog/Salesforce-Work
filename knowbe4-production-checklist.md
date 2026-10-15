# KnowBe4 sync: moving it to production

Status in EG-Sandbox as of 2026-09-30: fully working. 4,908 `KnowBe4_User_Result__c`
rows across 333 people and 31 modules, phish-prone percentage and risk score
populated on 4,907 of them, and `KnowBe4 Sync Daily` scheduled at 7:00 AM org
time (`0 0 7 * * ?`).

Nothing below has been done in production yet.

## Change set contents

Six Apex classes, and nothing else unless the verification step finds a gap:

| Component | Type |
| --- | --- |
| `KnowBe4Client` | Apex Class |
| `KnowBe4SyncService` | Apex Class |
| `KnowBe4SyncQueueable` | Apex Class |
| `KnowBe4SyncSchedulable` | Apex Class |
| `KnowBe4ClientTest` | Apex Class |
| `KnowBe4SyncServiceTest` | Apex Class |

The four production classes reference only each other and `KnowBe4Client`; the
two test classes reference only the classes above plus a live Salesforce `User`
they query at runtime. There is no shared test factory and no service or
selector layer to drag along, so this list is the whole dependency closure.

## Verify in production before building the change set

The objects and most fields predate this work and came down in the sandbox
refresh, so they should already exist in production. Confirm rather than
assume — a change set is atomic, and a single missing field fails the whole
validation.

1. `KnowBe4_Module__c` exists, with `Module_External_Id__c` (unique, external
   id) and `Due_Date__c` (required).
2. `KnowBe4_User_Result__c` exists, with `External_Id__c` (unique, external
   id), `User__c`, `KnowBe4_Module__c`, `Enrolled__c`, `Started__c`,
   `Completed__c`, `Score__c`, `Current_PPP__c`, `Risk_Score__c`.
3. `KnowBe4_User_Result__c.Status__c` has all four values: `passed`,
   `past_due`, `in_progress`, `not_started`. This is the one field this project
   has a local copy of, which suggests it was created or edited in the sandbox.
   If production is missing any value, add the field to the change set.
4. The two flows already exist: `KnowBe4_Results_Update_Owner` and
   `KnowBe4 Module: populate External Id`. Note the second one also writes
   `Module_External_Id__c`, which our Apex sets directly. That coexists fine in
   the sandbox, but it is two writers on one field.
5. The `KnowBe4_access` permission set exists and covers whoever needs to read
   the two objects.

## Named credential: manual, not in the change set

`knowbe4api` has to be created by hand in production. The API token lives in the
Password field, and change sets do not carry credentials, so shipping the
metadata would produce a credential that fails every callout.

- Name / API name: `knowbe4api`
- URL: `https://us.api.knowbe4.com`
- Authentication Protocol: Password Authentication
- Username: anything non-blank; it is unused
- Password: the KnowBe4 Reporting API token
- **Generate Authorization Header: OFF**
- **Allow Merge Fields in HTTP Header: ON**

That last checkbox is the one that cost us an afternoon in the sandbox. With it
off, `Authorization: Bearer {!$Credential.Password}` ships the literal merge
field and KnowBe4 answers `Invalid Token`.

## Order of operations in production

1. Create the named credential and save it.
2. Validate the change set. All Apex recompiles and the org needs 75% overall
   coverage, so validate before the deploy window rather than during it.
3. Deploy the change set.
4. Smoke test one campaign with `scripts/apex/runKnowBe4OneCampaign.apex`,
   editing the campaign id first. Confirm rows appear and emails match.
5. Backfill with `scripts/apex/runKnowBe4Sync.apex`. In the sandbox this ran as
   two chained Queueable jobs and finished in about two minutes.
6. Schedule with `scripts/apex/scheduleKnowBe4Sync.apex`. It aborts any
   existing job of the same name first, so it is safe to re-run.
7. Confirm: `SELECT COUNT(Id) FROM KnowBe4_User_Result__c` and
   `SELECT CronJobDetail.Name, State, NextFireTime FROM CronTrigger WHERE
   CronJobDetail.Name = 'KnowBe4 Sync Daily'`.

## Known behavior worth telling whoever owns this

- **Scope.** First production pull: campaigns count when they started on or
  after 2024-01-01 or are still open. Enrollments before that cutoff are
  dropped even inside an in-scope campaign. Follow-up deploy switches this
  to a rolling 18-month window.
- **Unmatched people.** An enrollment whose KnowBe4 email has no active
  Standard Salesforce User is skipped, not orphaned. The job logs the count and
  the addresses at WARN, so they are visible in the Apex job debug log. Three
  turned up in the sandbox.
- **Deletes.** An enrollment removed in KnowBe4 leaves its Salesforce row in
  place. Salesforce is the historical record; nothing prunes it.
- **PPP and risk score** are current user-level values copied onto every result
  row for that person, because there is no KnowBe4 user object to hang them on.
  They refresh whenever KnowBe4 reports a different number, so a person's score
  changing rewrites all of their rows. A missing value is treated as "KnowBe4
  said nothing," not "blank," so it never wipes a stored score.
- **Callout budget.** Each job handles 15 campaigns and pages enrollments at
  500 per page, plus one or two pages of users. A campaign with more than
  50,000 enrollments would need `CAMPAIGNS_PER_JOB` lowered.
