# Plan: Start Time in the External ID Key, and Removing Timesheet Collapsing

Target org: EG-Sandbox (`ausschultz04@gmail.com`). Production deploys are done by Austin, not by the agent.

## Goal

Two linked asks:

1. `EG_Time_Entry__c.ExternalID__c` should include the meeting start time, so two meetings on the same project, task and day each keep their own time entry instead of fighting over one key.
2. The weekly timesheet should stop collapsing multiple entries into a single cell.

These cannot ship separately. See "Why this is one deploy" below.

## Status: rolled back in `force-app`; still deployed in EG-Sandbox

The code below was implemented and deployed to EG-Sandbox, then reverted in the repo at Austin's request. `TimeEntryKey` is back to the four-part key, `egEventLogic` builds it inline again, and the timesheet collapses entries as it always did. Two things were deliberately kept because they belong to other work: the `Source_Event_Id__c` and `Time_Entry_Source__c` stamps that the Event Review page depends on, and the `Start_Time__c` field itself, which no code now reads or writes.

**The sandbox still holds five-part keys** written by the backfill, and `EventTrigger` is still pointed at `egEventLogic`. Redeploying `force-app` over the sandbox without reversing that data will leave entries whose keys the timesheet cannot regenerate -- which the delete sweep now removes again. See "Why this is one deploy" below; it describes the same hazard in the opposite direction.

## What was implemented and deployed to EG-Sandbox

Done, with two deviations from the plan below:

- **The discriminator is the Event Id, not the start time.** The key is only a uniqueness guard now — nothing reconstructs it to find records — so the collision-proof option won. `Start_Time__c` is still stamped and is what labels a meeting row in the timesheet; it just is not key material.
- **`force-app`'s `egEventLogic` turned out to be broken, not merely divergent.** Its line 25 query had been commented out and replaced with one omitting `AttendeeIDs__c` while line 33 still read that field, so every Event insert would have thrown `SObjectException`. That is why the trigger had been pointed at `blogic_Event`. The working copy was restored from the org and the intended edits reapplied on top; the broken work-in-progress was discarded.

56 tests pass. The backfill ran twice in sandbox, updating 3 entries then reporting them already correct.

Phase 1 groundwork, also complete and deployed:

- `EG_Time_Entry__c.Start_Time__c` (Time) exists in EG-Sandbox, deploy `0AfWL00000HtPX50AN`. Nothing reads or writes it.
- 15 Apex classes and 3 LWCs were pulled from the org into `force-app`, including `TimeEntryKey`, which phase 2 has to edit.
- A dry-run deploy of all of `force-app` compiles with zero Apex errors.

Phase 2 is everything below and has not started.

---

## Step 0 — Blocker: `EventTrigger` points at a different handler in the org than in the repo

This has to be settled before any key work, because it determines which class is the live one to edit.

The org's `EventTrigger`:

```apex
egEventLogic.createEGTimeEntry(Trigger.newMap);
//blogic_Event.createEGTimeEntry(Trigger.newMap);
```

`force-app`'s `EventTrigger`:

```5:5:force-app/main/default/triggers/EventTrigger.trigger
        blogic_Event.createEGTimeEntry(Trigger.newMap);
```

The two are exact inversions of each other. **In the org, `egEventLogic` is the live Event-to-Time-Entry automation and `blogic_Event` is dead code. In the repo it is the other way around.** Deploying `force-app`'s trigger as-is would silently swap the entire automation implementation — different dedup logic, different attendee handling, different field stamping.

Three consequences that are already biting:

**a. Automation entries are being saved with a blank source.** The org's `egEventLogic` stamps `Time_Entry_Source__c = 'Automation'` in its owner loop but not in its EventRelation/attendee loop. `force-app`'s copy stamps both. This is why `egEventLogicTest.testGenerateTimeEntry` fails with `Expected: Automation, Actual: null`, and it is real data, not just test data — the org currently holds 2 entries with `Created_with_Automation__c = true` and a null source.

**b. The Event Review page cannot see automation-created entries.** The work shipped earlier this session made `EG_Time_Entry__c.Source_Event_Id__c` the Event-to-entry link, on the understanding that the automation already stamps it. `blogic_Event` does stamp it:

```697:699:force-app/main/default/classes/blogic_Event.cls
        te.Source_Event_ID__c =
            String.valueOf(e.Id);
```

`egEventLogic` — the class actually running in the org — contains no reference to `Source_Event` at all. So every entry the live automation creates has a blank `Source_Event_Id__c` and will never match an Event on the review page. Only 3 entries in the org have the field populated, and those are the ones the migration script backfilled.

**c. The key is built in both handlers**, so "change it everywhere" depends on knowing which one survives.

### Decision: minimal alignment, no consolidation

The Event-to-Time-Entry automation is being rebuilt in Flow later, so the two Apex handlers are both on their way out. That rules out any work whose only payoff is a tidier trigger layer. Do the cheapest thing that defuses the landmine and nothing more:

1. **Point `force-app`'s `EventTrigger` at `egEventLogic`, matching the org.** One line, zero org impact, and it stops anyone from swapping the live automation by accident on an unrelated deploy.
2. **Fix `egEventLogic`'s two gaps in place** — stamp `Time_Entry_Source__c` in the attendee loop, stamp `Source_Event_Id__c` in both loops. These are live data bugs and the fix is a handful of lines.
3. **Leave `blogic_Event` alone.** It is dead code in the org. Retiring it properly is real effort with no user-visible payoff, and the Flow migration deletes the question entirely. Add a header comment saying it is not wired up, so the next person does not assume it runs.

Explicitly not doing: switching the live automation to `blogic_Event`, or refactoring `egEventLogic` beyond the two stamps.

---

## Why this is one deploy

`saveTimesheetApex` deletes every entry on the time card whose `ExternalID__c` it did not just generate:

```314:320:force-app/main/default/classes/egTimesheet_Ctlr.cls
        //perform delete...
        for (String s : existingEntryMap.keySet()) {
            if (!currentEntries.contains(s)){
                entriesToDelete.add(existingEntryMap.get(s));
            }
        }
        if(!entriesToDelete.isEmpty()) delete entriesToDelete;
```

Once a meeting entry's key carries a start time, the grid will never regenerate that key, so the next timesheet save deletes it. Shipping the key change without the timesheet rework destroys data on first save.

The reverse also fails. An earlier idea — keep the grid summing for display but stop it deleting what it did not write — causes double counting: the meeting entry gets summed into the cell on read, and then the grid writes its own aggregate row for the same project, task and day on save. Both records then exist and the hours are counted twice.

---

## Design

### The key format

Append the start time **only when there is one**:

| Row type | `Start_Time__c` | `ExternalID__c` |
| --- | --- | --- |
| Typed into the timesheet | null | `card:proj:task:2026-07-24 00:00:00` |
| Created from a meeting | 12:00 | `card:proj:task:2026-07-24 00:00:00:1200` |

This is the safe choice: **every existing manual entry keeps the key it already has**, so the backfill touches only meeting-derived rows rather than the whole table.

Two details worth pinning down in tests, in the same spirit as the existing `TimeEntryKeyTest`:

- The date must keep rendering as `2026-07-24 00:00:00`. `String.valueOf(Date)` emits the short form and silently stops matching stored keys. This is already locked by `TimeEntryKeyTest` and must stay locked.
- Format the time as compact `HHmm`, not raw. Concatenating a `Time` into a string yields `12:00:00.000Z`, which embeds colons into a colon-delimited key. Nothing splits `ExternalID__c` today, but leaving that in is asking for trouble.

`ExternalID__c` is Text(255); the current key is about 76 characters, so four more is not a concern.

**Residual risk to accept or reject:** two distinct meetings at the same start time on the same project, task and day still collide. The fully collision-proof discriminator is the Event Id, which is already available in `Source_Event_Id__c`. Start time is what was asked for and reads better in the data; flagging it as an open question below.

### The timesheet

Partition entries on the card by whether `Start_Time__c` is set:

- **Grid-owned rows (`Start_Time__c == null`)** behave exactly as they do today: one row per project/task, aggregated across the week, upserted by the 4-part key, and still subject to the delete-what-I-did-not-write sweep — but that sweep is now scoped to grid-owned entries only.
- **Meeting rows (`Start_Time__c != null`)** render one row per entry, are never aggregated, and are never deleted by the grid. They carry their entry Id so edits save by Id rather than by key.

Keeping meeting rows editable matters: today those hours *are* editable, because they are merged into a grid cell. Making them read-only would be a capability regression.

---

## Work breakdown

### 1. Key builders — five places

| File | What changes |
| --- | --- |
| `TimeEntryKey.cls` | Add an overload taking `Time startTime`; keep the 4-arg signature delegating to it with null |
| `egEventLogic.cls` | Two inline builds (lines 141, 174) replaced with `TimeEntryKey.build(...)`, passing the event start time |
| `OutlookEventReviewController.externalIdFor` | Add the start time parameter; ideally delegate to `TimeEntryKey` rather than duplicating |
| `egTimesheet_Ctlr.saveTimesheetApex` | Line 280 inline build replaced with `TimeEntryKey.build(...)`, start time null for grid rows |
| `blogic_Event.buildExternalId` | Leave as-is — dead code, and the Flow migration removes it |

Collapsing the live builders onto `TimeEntryKey` is the point of the exercise — right now the format is copy-pasted five times and has already drifted once.

**Give `TimeEntryKey` an `@InvocableMethod` wrapper as part of this work.** When the automation moves to Flow, that Flow has to produce a byte-identical key or it will insert duplicates instead of matching existing entries. A Flow cannot call a plain static method, so without an invocable entry point the key format will get hand-rebuilt in a formula as a sixth copy — and the two gotchas this format carries (the date rendering as `2026-07-24 00:00:00`, null lookups rendering as the literal `null`) are exactly the kind of thing that will not survive being retyped in a Flow formula. Building the wrapper now, while the format is already being edited and tested, is far cheaper than discovering the mismatch after the Flow goes live.

### 2. Automation stamps the new fields

In `egEventLogic`, both creation loops set:

- `Start_Time__c` from the `Event.StartDateTime`, converted to the event owner's local time
- `Source_Event_Id__c` from `String.valueOf(event.Id)` — closes gap (b) from Step 0
- `Time_Entry_Source__c = 'Automation'` in the attendee loop — closes gap (a)

Timezone is the thing to be careful with here. `Date__c` is already derived as `date.newinstance(dT.year(), dT.month(), dT.day())` from the raw `StartDateTime`, which is a known-sloppy pattern in this codebase; the start time must be derived the same way so the two stay consistent with each other.

### 3. Timesheet read path

`getTimesheetForDateApex`, around lines 108–146: query `Start_Time__c` and `Id`, then route each entry to either the aggregating `rowMap` or a standalone meeting row. Meeting rows sort after grid rows within the same project/task. The prefill block (lines 149–192) only ever looks at project/task, so it is unaffected, but it must not prefill from meeting rows.

### 4. Timesheet save path

`saveTimesheetApex`, lines 219–321:

- Scope `existingEntries` to `Start_Time__c = null` so the delete sweep can never reach a meeting entry.
- Rows arriving with an `entryId` and a start time update that record by Id; they do not participate in the project/task aggregation map.
- Leave the `'Timesheet'` source stamp behavior as-is for grid rows.

### 5. `TimesheetRow` and the LWC

`TimesheetRow` gains `entryId`, `startTime`, `startTimeLabel` and `isMeeting`. `egTimesheet.html` renders meeting rows with the time shown next to the task and the project/task lookups locked (the meeting determines those, not the user). `egTimesheet.js` needs `getNewRow()`, `calculate()` and the last-row-append logic to stay correct when meeting rows are present — the current code assumes every row is a 7-cell week row, so the append-a-blank-row check needs to skip meeting rows.

### 6. Backfill

A re-runnable anonymous Apex script in `scripts/apex/`, same pattern as `migrate-event-entry-link.apex`:

1. Find entries where `Start_Time__c` is null and `Source_Event_Id__c` is not null (automation entries created before this change).
2. Look up the source Event, set `Start_Time__c` from its `StartDateTime`.
3. Recompute `ExternalID__c` via `TimeEntryKey.build`.
4. Report any key collisions rather than throwing, so it can be run, read, and re-run.

In EG-Sandbox this touches at most 3 records. Production will be larger and needs a count check first.

Because there is no git here, **export `Id, ExternalID__c, Start_Time__c` for all `EG_Time_Entry__c` to CSV before running the backfill**. That export is the rollback artifact.

### 7. Tests

- Extend `TimeEntryKeyTest` with the start-time cases, keeping both existing assertions untouched.
- `egEventLogicTest` should pass once the attendee-loop stamp is fixed; add assertions for `Start_Time__c` and `Source_Event_Id__c`.
- New `egTimesheet_Ctlr` tests for the two behaviors that matter: a meeting entry and a manual entry on the same project/task/day produce two rows and two records, and a timesheet save does not delete the meeting entry.
- Re-run the full suite used in phase 1 verification (52 tests across 9 classes).
- Deploys use `RunSpecifiedTests`, which requires ≥75% coverage per selected class.

---

## Deploy and rollback

One atomic deploy containing: `TimeEntryKey`, `egEventLogic`, `EventTrigger`, `OutlookEventReviewController`, `egTimesheet_Ctlr`, the `egTimesheet` LWC, and the test classes. Sandbox first, manual verification of both a meeting-driven and a hand-typed week, then Austin deploys to production and runs the backfill.

Rollback is a redeploy of the prior class versions plus a reverse backfill from the CSV export. It is not a `git revert`, so the CSV is not optional.

---

## Note on the Flow migration

The Event automation is moving to Flow later. Two things in this plan are deliberately shaped around that:

- **Nothing here invests in the Apex trigger layer beyond bug fixes.** No handler consolidation, no refactor of `egEventLogic`, no retirement of `blogic_Event`.
- **The key format gets an invocable entry point** so the future Flow reuses it rather than reimplementing it. This is the one piece of this work the Flow migration will directly depend on.

Worth deciding separately: whether `Start_Time__c` and `Source_Event_Id__c` should be stamped by the current Apex at all, or whether that should wait and ship as part of the Flow. Stamping them now means the Event Review page starts working against automation entries immediately instead of after the Flow lands, but it is work that the Flow will then supersede.

## Open questions

1. **Collision discriminator:** start time as asked, or Event Id for guaranteed uniqueness? The Event Id is already on the record in `Source_Event_Id__c`.
2. **Meeting rows in the grid:** editable (preserves today's capability, recommended) or read-only?
3. **Scope of the `egEventLogic` fixes:** should the `Source_Event_Id__c` and `Time_Entry_Source__c` stamps ship now as a small standalone fix, ahead of the key work? They are independent of the key change and both fix live bugs — but see the Flow note above.
4. **Flow timing:** if the Flow migration is close, the timesheet rework still stands on its own but the automation-side edits may be better folded into the Flow build.
