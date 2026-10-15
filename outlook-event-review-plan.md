# Plan: make Outlook Event Review self-contained

Status: implemented and deployed to EG-Sandbox, 10/10 tests passing.

Goal: the table writes its own time entries so it no longer depends on the
Outlook panel's service layer. The change set goes back to 7 components with
zero extra Apex.

Principles for this work: keep it flat. No service class, no selectors, no
request DTO. Inline SOQL and DML in the controller, the way the rest of
`OutlookEventReviewController` is already written.

## What gets removed

The component currently imports two Apex methods that pull in the whole July
time-entry stack:

- `TimeEntryController.createTimeEntry` (drags in `TimeEntryService`,
  `TimeEntryRequest`, `TimeEntrySummary`, `TimeEntryKey`, `TimeEntrySelector`,
  `TimeCardSelector`, `ProjectSelector`, `ProjectTaskSelector`)
- `OutlookEventReviewController.linkTimeEntry` (ours, folded into the new method)

The test class also calls `TestDataFactory`, so that has to go too or the
dependency survives in the change set.

Notes came out of the table and the code entirely: the `timeEntryNotes` row
field, `Notes__c` in both queries, and the fallback in `matchEntry` that
treated a time entry whose notes equalled the event subject as a match. Rows
now show an existing entry only when the Event is linked to it or when an
entry for that day carries the row's project.

## New Apex: one method on the existing controller

```apex
@AuraEnabled
public static Id saveTimeEntry(
    Id eventId,
    Date workDate,
    Decimal hoursWorked,
    Id projectId,
    Id projectTaskId
)
```

Steps, in order:

1. Validate. `eventId` present and an Event key prefix; `workDate` present;
   `hoursWorked > 0`; `projectId` present. Each failure throws
   `AuraHandledException` with a message the user can act on.
2. If `projectTaskId` is set, one query confirms it belongs to `projectId`.
   Reject a mismatch rather than silently fixing it.
3. Find the running user's weekly time card covering `workDate` — the same
   inline query `setWorkingLocation` already uses. No card means a friendly
   error telling them to create the week's card first.
4. Build `ExternalID__c` (see contract below).
5. `upsert entry ExternalID__c` — the field is a true unique External ID, so
   one statement updates `egEventLogic`'s draft or inserts a new entry. Every
   field in the payload except the hours is part of the key, so a match only
   ever changes the hours. `Created_with_Automation__c` is left off the payload
   so the automation keeps its flag and new rows take the default of false.
7. Set `Event.EG_Time_Entry__c` to the entry, only when it changed.
8. Return the entry Id.

## The ExternalID__c contract

`egEventLogic` has been live since 2022 and writes the key inline:

```apex
String externalId = te.EG_Time_Card__c+':'+te.EG_Project__c+':'+te.EG_Project_Task__c+':'+te.Date__c;
```

`ExternalID__c` is unique, so our expression has to produce the identical
string or saves collide or duplicate. We write the same concatenation, in the
same order, with the same types — notably concatenating the `Date` directly
rather than `String.valueOf(...)`, which would emit a shorter form and never
match stored keys. One comment naming `egEventLogic` earns its place here, plus
a test that locks the format.

## Component changes

- Drop the `createTimeEntry` and `linkTimeEntry` imports; add `saveTimeEntry`.
- `saveRow` skips the write unless there's a project and hours greater than zero,
  then calls `saveTimeEntry` with discrete arguments instead of a request object.
- Hours write on blur instead of on every change. Project, task, and location
  still write on selection, since those are discrete choices.
- The returned Id sets `row.timeEntryId` and `row.hasTimeEntry`, which is what
  the "Time entry" filter reads.
- The working-location call stays exactly as it is.

## Behavior decisions

| Question | Decision |
| --- | --- |
| Key already exists (automation drafted it) | Update hours in place |
| Project required before saving | Yes — without it the key degrades to `card:null:null:date` and two meetings on one day collide |
| Task required | No |
| When rows write | Hours on blur; pickers on selection |
| Fields written | Card, date, hours, project, task, key, `Created_with_Automation__c` = false |
| Fields skipped | Notes, Time Category, Internal, Opportunity back-fill — no columns for them |
| Delete icon | Unchanged: deletes the Event only |
| Location column | Unchanged |

## Tests

Replace the four `TestDataFactory` calls with private helpers in
`OutlookEventReviewControllerTest`, then add:

- inserts a new entry and links it to the event
- updates an existing entry matched by key, rather than inserting a second
- the built key matches the `egEventLogic` concatenation exactly
- rejects: no project, hours of zero, no time card for the week, task from a
  different project

## Change set after this

The original seven: `OutlookEventReviewController`,
`OutlookEventReviewControllerTest`, `egOutlookEventReview`,
`EGNoFlexipageHeader`, the Outlook Event Review page, the tab, and the
permission set. Nothing else.

## Risks

- **Divergence.** Two places now build the key. The format test is the guard.
- **Race on the unique key.** `upsert` by external id closes the read-then-write
  gap. Two genuinely concurrent saves of the same key can still error, and the
  user retries.
- **Overlapping time cards.** `egEventLogic.findTimeCard` takes the first row of
  an unordered query; we take the newest by `Start_Date__c`. If a user somehow
  has two cards covering one date, the two writers pick different cards, build
  different keys, and produce two entries for the same work.
- **Sharing.** The July service used `insert as user`. This controller uses
  plain DML under `with sharing`; staying consistent with the file, but worth a
  conscious yes.
- **Divergent logic over time.** The Outlook panel's service keeps its own
  validation. If the rules change, someone has to change both — accepted
  tradeoff for shipping without the undeployed stack.

## Rollback

Nothing is deleted from the sandbox: the July classes stay where they are. To
revert, redeploy the current controller and component.
