# Time entry and Event logic

Every path that creates, edits or deletes an `EG_Time_Entry__c` record, and how the Event side feeds it.

**Source:** `force-app` and `metadata-audit` snapshots, cross-checked against EG-Sandbox (`00DWL00000BtPgz2AF`) via the Tooling API.
**Date:** 7 October 2026


|                                 |     |
| ------------------------------- | --- |
| Ways a row is written           | 5   |
| Shared uniqueness key           | 1   |
| Classes live in the org         | 19  |
| Of those, missing from the repo | 9   |


---

## The one invariant everything depends on

Four independent writers build the same uniqueness key by hand. It is the only thing stopping the Event trigger, the timesheet grid, the Outlook panel and the Event Review page from each writing their own duplicate row for the same work.

```
EG_Time_Entry__c.ExternalID__c = timeCardId + ':' + projectId + ':' + projectTaskId + ':' + workDate
```

`Text(255)`, unique, external id.

Two details are easy to get wrong and are locked by `TimeEntryKeyTest`:

- A null task renders as the literal string `null`.
- The Date renders through Apex concatenation as `2026-07-24 00:00:00`, **not** `2026-07-24`.

Using `String.valueOf(date)` instead produces the short form and silently stops matching every key already stored. There is a comment in `OutlookEventReviewController.externalIdFor` warning about exactly this, which suggests someone has already been burned by it.

Built in four places:

- `TimeEntryKey.build`
- `blogic_Event.buildExternalId`
- `egEventLogic` (inline, twice)
- `OutlookEventReviewController.externalIdFor`

---

## Five ways a time entry is written

Four of these are custom code and each stamps a different `Time_Entry_Source__c`, which is the fastest way to tell where a row came from. The fifth is the standard record UI, which stamps nothing.


| Surface                   | Fires when                         | Apex                                                       | Source stamp        | Write strategy                                                    |
| ------------------------- | ---------------------------------- | ---------------------------------------------------------- | ------------------- | ----------------------------------------------------------------- |
| **Event trigger**         | Event insert / update              | `blogic_Event.createEGTimeEntry`                           | `Automation`        | Insert only, after two dedup passes                               |
| **Weekly timesheet grid** | User edits a cell (1s debounce)    | `egTimesheet_Ctlr.saveTimesheetApex`                       | `Timesheet`         | Upsert by `ExternalID__c`; deletes rows no longer in the grid     |
| **Outlook Inbox panel**   | User presses Create / Edit         | `TimeEntryController.createTimeEntry` → `TimeEntryService` | `Outlook_Panel`     | Targeted edit by Id when `timeEntryId` is set, else upsert by key |
| **Event Review page**     | Hours blur, project or task change | `OutlookEventReviewController.saveTimeEntry`               | `Event_Review_Page` | Upsert by `ExternalID__c`, then claims the Event                  |
| **EG Time Entry tab**     | Standard record UI                 | none — standard DML                                        | *(blank)*           | No key enforcement beyond the unique index                        |


---

## Event to time entry, step by step

The only automatic path. `EventTrigger` fires after insert and after update and hands the whole `Trigger.newMap` to `blogic_Event.createEGTimeEntry`. There is no batch, no scheduled job and no flow in this path — it is entirely synchronous.

1. **Filter the Events.** `WhatId` must point at an `EG_Project__c`. Recurrence series and child occurrences are skipped. Nothing else qualifies.
2. **Resolve people.** Owner plus every `EventRelation`. Contacts map to Users by `Contact.Email = User.Username` first, then by a unique `User.Email`.
3. **Build candidates.** One draft per person per event. Hours come from `DurationInMinutes / 60`. Task is filled only when the project has exactly one.
4. **Drop duplicates.** Two passes, then insert. Entries are never updated by the trigger — only created.

### Dedup pass 1 — the business key

Skip the draft if any entry already has the same `ExternalID__c`. This is what stops a second Event for the same project, task and day from double-booking the week, and it is also what lets the Outlook panel and Event Review page later merge into a row the automation drafted.

### Dedup pass 2 — same event, same person

Skip the draft if an entry already carries this `Source_Event_Id__c` on this person's time card. This replaced the old `AttendeeIDs__c` ledger on the Event.

It is also why logging an event by hand now suppresses the automation for that event — and why deleting that entry lets the automation draft it again.

### Fields the automation stamps

```apex
te.Date__c                    = e.StartDateTime.date();
te.Hours_Worked__c            = Decimal.valueOf(e.DurationInMinutes) / 60;
te.EG_Time_Card__c            = timeCardId;
te.Created_with_Automation__c = true;
te.Time_Entry_Source__c       = 'Automation';
te.EG_Project__c              = e.WhatId;
te.Source_Event_ID__c         = String.valueOf(e.Id);
te.EG_Project_Task__c         = <only when the project has exactly one task>;
te.ExternalID__c              = buildExternalId(te);
```

Notes, Opportunity, Time Category and Internal are left unset.

---

## How an Event and its entry are linked

> **This changed on 7 Oct 2026.** The link used to be a lookup on Activity (`Activity.EG_Time_Entry__c`). That field was deleted and the relationship now runs the other way, stored as an 18-character Id in `EG_Time_Entry__c.Source_Event_Id__c` — the field `blogic_Event` was already writing. The deleted field currently shows in the org as `EG_Time_Entry_del`, so it is recoverable from the recycle bin for 15 days.

Because the link is plain text rather than a lookup, nothing at the database level enforces one entry per event. The controller compensates with a `releaseOtherEntries` helper that clears any stale claim whenever a row is replaced, and every read is scoped to the running user's own time cards so a shared event cannot surface or delete someone else's time.

---

## Data model essentials

### `EG_Time_Entry__c`

45 fields, most of them formulas. Master-detail to the time card, so sharing is controlled by the parent and the card is effectively required. The fields that carry behaviour:


| Field                        | Role                                           |
| ---------------------------- | ---------------------------------------------- |
| `ExternalID__c`              | Text(255), unique, external id — the merge key |
| `Source_Event_Id__c`         | Text(18) — the Event that owns this row        |
| `Time_Entry_Source__c`       | Picklist — which surface wrote it              |
| `EG_Time_Card__c`            | Master-detail, reparentable                    |
| `Created_with_Automation__c` | Set true by every custom writer                |


### `EG_Time_Card__c`

Private sharing, one per user per week. Every writer resolves it the same way: owned by the running user, with the work date between `Start_Date__c` and `End_Date__c`. If no card exists, the save is refused rather than auto-created.


| Field                    | Role                                         |
| ------------------------ | -------------------------------------------- |
| `TimeCardExternalId__c`  | Unique external id — owner plus week start   |
| `Hours_Worked__c`        | Roll-up sum of child entries                 |
| `Client_Hours__c`        | Roll-up filtered to `Time_Category = Client` |
| `Location_Monday__c`     | One picklist per weekday, Mon–Fri            |
| `Location_Completion__c` | Percent formula over those five              |


No Apex triggers exist on `EG_Time_Entry__c`, `EG_Time_Card__c`, `EG_Project__c` or `EG_Project_Task__c`. Downstream behaviour on these objects is all record-triggered flows — category defaulting, department population, opportunity lookup and project hour roll-ups.

---

## Findings

### High

**1. `force-app` cannot compile on its own.**
Nine classes that `force-app` code directly references exist only in the `metadata-audit` snapshot: `TimeEntryController`, `TimeEntryRequest`, `TimeEntryKey`, `TimeEntrySelector`, `TimeEntrySummary`, `TimeCardSelector`, `ProjectSelector`, `ProjectTaskSelector`, `TestDataFactory`. All nine **are** present in the org (verified by Tooling API query), so nothing is broken at runtime — but a clean deploy from `force-app` alone would fail, and nobody can review or change that code from the repo.
*Where:* `force-app/main/default/classes/TimeEntryService.cls:18-24`, `lwc/outlookTimeEntry/outlookTimeEntry.js:2`

**2. Two competing Event automations exist side by side.**
`force-app`'s `EventTrigger` calls `blogic_Event` and has the `egEventLogic` call commented out. The `metadata-audit` copy of the same trigger still calls `egEventLogic`. Both classes are deployed in the org. They implement the same feature with different rules, and only `blogic_Event` stamps `Source_Event_Id__c`. If the older trigger were ever restored, both would run and double-write.
*Where:* `force-app/main/default/triggers/EventTrigger.trigger:4-5`

### Medium

**3. Upsert-by-key silently ignores project and task changes.**
When `TimeEntryService.createEntry` matches an existing row by `ExternalID__c`, it calls `applyRequest`, which writes only `Hours_Worked__c`, `Notes__c`, `Time_Category__c` and `Internal__c`. Opportunity, Project and Task are **not** written on that path — they are only set by `buildEntry` on insert and by `updateTargetedEntry` on a targeted edit. A user changing the project on a matched row may see it quietly not stick.
*Where:* `TimeEntryService.cls:209-220` vs `272-291`

**4. Nothing blocks logging time to an inactive project.**
`validateAndResolveSelections` checks that the task belongs to the project and the project belongs to the opportunity, but never looks at `EG_Project__c.Status__c` or `EG_Project_Task__c.Status__c`. Only the lookup UI filters on Active, so any caller bypassing the picker can log to an inactive project.
*Where:* `TimeEntryService.cls:228-256`

**5. Delete works only because Apex skips CRUD checks.**
The `Outlook_Time_Entry_User` permission set grants Create and Edit on `EG_Time_Entry__c` but not Delete. `deleteTimeEntryForEvent` still succeeds, because plain Apex DML does not enforce object permissions — `with sharing` governs record visibility, not CRUD. It works today, but the permission set no longer describes what the feature can actually do.
*Where:* `OutlookEventReviewController.deleteTimeEntryForEvent`; `Outlook_Time_Entry_User.permissionset-meta.xml`

**6. Two different sharing postures on the same object.**
`TimeEntryService` uses `insert as user` / `update as user`, enforcing CRUD and FLS. `egTimesheet_Ctlr` is declared `without sharing` and uses plain DML. The weekly grid and the Outlook panel therefore apply different security to the same records.
*Where:* `egTimesheet_Ctlr.cls:1` vs `TimeEntryService.cls:88-95`

**7. `Source_Event_Id__c` is an unindexed text scan.**
The Event Review page filters `EG_Time_Entry__c` with `Source_Event_Id__c IN :eventKeys` against up to 500 event ids on every load, and `blogic_Event` queries it the same way on every Event trigger. The field is plain `Text(18)` with `externalId` false, so neither query is selective. Fine at today's volume; marking it an external id would index it.
*Where:* `force-app/main/default/objects/EG_Time_Entry__c/fields/Source_Event_Id__c.field-meta.xml`

**8. `egEventLogic` picks a time card non-deterministically.**
`egEventLogic.findTimeCard` runs a per-attendee SOQL with no `ORDER BY` and takes row zero. If a user has overlapping time cards, which one receives the entry is undefined. `blogic_Event` fixed this by ordering `Start_Date__c DESC` and taking the newest overlapping week.
*Where:* `egEventLogic.cls:208-222`

### Low

**9. A metrics method always returns empty.**
`egTimesheetMetrics_Ctlr.queryTimecardsByDate(Date)` ignores its argument and delegates to `queryTimecards(null)`, which produces an empty wrapper. The LWC also passes a `timecardId` that the Apex never reads — only `userid` is used.
*Where:* `egTimesheetMetrics_Ctlr.cls:5-7`

**10. `egEventLogicTest` does not test `egEventLogic`.**
The test inserts and updates Events and asserts an entry was created with `Time_Entry_Source__c = 'Automation'`. Because the live trigger calls `blogic_Event`, this test actually covers `blogic_Event`. `blogic_Event` has no test class of its own, so the name understates what it protects — and overstates what covers `egEventLogic`.
*Where:* `force-app/main/default/classes/egEventLogicTest.cls`

**11. Deleting an Event leaves its time entry behind.**
The trash can in the Event Review table calls `deleteEvent`, which removes the Event only. Now that the link lives on `EG_Time_Entry__c.Source_Event_Id__c` rather than a lookup from Activity, the entry survives with a `Source_Event_Id__c` pointing at an id that no longer resolves.
*Where:* `OutlookEventReviewController.deleteEvent`

---

## What is in the org versus the repo

All 19 classes below are deployed and compiling in EG-Sandbox. The ten marked **tracked** are editable from `force-app`; the nine marked **untracked** exist only as read-only copies under `metadata-audit`, which is a stale retrieve rather than a source of truth.


| Class                          | API | Role                                  | In force-app  |
| ------------------------------ | --- | ------------------------------------- | ------------- |
| `blogic_Event`                 | 68  | Live Event→entry automation           | tracked       |
| `OutlookEventReviewController` | 62  | Event Review page + panel match       | tracked       |
| `OutlookIdStampController`     | 62  | Stamps `Outlook_iCalUId__c`           | tracked       |
| `TimeEntryService`             | 67  | Panel create/edit service             | tracked       |
| `egTimesheet_Ctlr`             | 54  | Weekly grid backend                   | tracked       |
| `egTimesheetMetrics_Ctlr`      | 55  | Metrics sidebar                       | tracked       |
| `egCustomLookup_Ctlr`          | 54  | Shared inline lookup search           | tracked       |
| `egEventLogic`                 | 55  | Superseded automation, still deployed | tracked       |
| `egTimeCardGenerationBatch`    | 55  | Creates weekly time cards             | tracked       |
| `egTimeCardGenerationSched`    | 55  | Schedules the batch                   | **untracked** |
| `TimeEntryController`          | 67  | `@AuraEnabled` wrapper for the panel  | **untracked** |
| `TimeEntryRequest`             | 67  | Panel DTO                             | **untracked** |
| `TimeEntryKey`                 | 67  | Builds the canonical key              | **untracked** |
| `TimeEntrySelector`            | 67  | Entry SOQL                            | **untracked** |
| `TimeEntrySummary`             | 67  | Read model                            | **untracked** |
| `TimeCardSelector`             | 67  | Weekly card lookup                    | **untracked** |
| `ProjectSelector`              | 67  | Project SOQL                          | **untracked** |
| `ProjectTaskSelector`          | 67  | Task SOQL                             | **untracked** |
| `TestDataFactory`              | 67  | Shared test fixtures                  | **untracked** |


The snapshot is also behind on behaviour, not just presence: its copies of `egTimesheet_Ctlr`, `egTimesheetMetrics_Ctlr` and `egTimeCardGenerationBatch` still contain the `EG_Time_Card_Compliance__c` logic that `force-app` removed, and its `EventTrigger` still calls `egEventLogic`.

> A second `TestDataFactory` also appears in the org under the `ah_businesscard` managed-package namespace. It is unrelated and does not conflict.

---

## Test coverage

**Well covered.** `OutlookEventReviewController` has 21 tests and `TimeEntryService` has 18, including every exception branch, the targeted-edit path and key collisions.

**Thin.** `egTimesheet_Ctlr` has a single test that mostly asserts no exception is thrown, despite being the busiest writer and the one with delete logic.

**Untested from the repo.** `blogic_Event` has no test of its own. Tests for the controller, selectors, key and custom lookup live only in the snapshot.

---

## Suggested next steps

1. **Pull the nine untracked classes into `force-app`.** They are deployed and working, but you cannot review or change them from the repo today, and a clean deploy would fail.
2. **Decide whether `egEventLogic` should be deleted.** Leaving a second, subtly different implementation of the same automation deployed is the kind of thing that bites during an incident.
3. **Fix the `applyRequest` gap** (finding 3) so a project or task change on a key-matched row is not silently dropped.
4. **Give `blogic_Event` a real test class** and rename `egEventLogicTest` to reflect what it actually exercises.

