# uPlan: remove EG Time Card Compliance

Status: done in EG-Sandbox. `EG_Time_Card_Compliance__c` is gone.

`EG_Time_Card_Compliance__c` is a yearly rollup: one row per user per calendar
year, keyed `OwnerId + year`. Weekly `EG_Time_Card__c` records look it up.
A flow rewrites the year's hours and "cards in compliance" whenever a card's
`Hours_Worked__c` changes. The timesheet metrics panel is the only runtime
reader, and the score / client / internal hours block in that panel is already
hidden (`slds-hide`). What users actually see is a list of weeks computed
straight from time cards and entries.

So this object is a denormalized cache plus a parent for reports/list views.
Removing it means computing (or dropping) those annual numbers at read time,
and stopping the writers.

## What still needs a product call

1. **Timesheet heading.** Today it shows "{year} Compliance" from
  `Annual_Timecard_Compliance_Start_Date__c`. After removal, the year is just
   `Date.today().year()`. Same heading, no object.
2. **Hidden score card.** `Compliance_Score__c`, `% Client Hours`, `% Internal
  Hours` are in the LWC but not visible. If nobody wants that block back, do
   not rebuild it. If HR still reports on those fields, they need a report off
   time cards instead, or the score has to be computed in Apex when the page
   loads.
3. **Reports and list views in production.** We have not retrieved Report
  metadata. Search Setup for reports/dashboards/list views on this object
   before deleting it. Known list views: All, Mismatched_Depts, 2022, 2023.
4. **Historical rows.** Delete the records with the object, or leave them until
  the object itself is deleted. Nothing else in Apex needs the old data once
   the lookup is gone.

Recommended default, matching "self-contained, do not maximize abstraction":
stop writing the object, stop querying it, drop the lookup, keep the weekly
metrics table as it already works. Do not add a new service or a replacement
rollup object.

## Replacement, in the files that actually use it

### 1. `egTimeCardGenerationBatch`

Delete the compliance upsert. Insert time cards the same way, without
`EG_Time_Card_Compliance__r`.

Today (keep the card loop, drop the compliance block):

```apex
EG_Time_Card_Compliance__c tComp = new EG_Time_Card_Compliance__c();
tComp.Name = u.FirstName + ' ' + u.LastName + ' ' + d.year();
// ...
tComp.External_Id__c = tComp.OwnerId + '' + tComp.Year__c;
tc.EG_Time_Card_Compliance__r = new EG_Time_Card_Compliance__c(
    External_Id__c = tComp.External_Id__c
);
```

After:

```apex
// No compliance parent. TimeCardExternalId__c is already the unique week key.
allTimeCards.add(tc);
```

Also remove `timecardCompliancesToUpsert`, `complianceExternalIds`, and
`upsert timecardCompliancesToUpsert External_Id__c`. `firstMonday` can stay if
something else still needs it; after this class it is unused and can go.

### 2. `egTimesheet_Ctlr` (create-card-for-this-week)

Same idea. It currently upserts a compliance row, then points the new or
existing card at it via external id. After the change, insert/upsert the card
only.

Remove the `tComp` construct around lines 87–97 and both assignments of
`timeCard.EG_Time_Card_Compliance__r`.

### 3. `egTimesheetMetrics_Ctlr`

This is the only reader. Two jobs:

- Stop requiring a compliance row. `queryTimecards` currently queries
`WHERE External_Id__c = :key` with no try/catch; a user with no row gets an
empty metrics panel.
- January last-year cards are fetched by `EG_Time_Card_Compliance__c = lastId`.
Replace that with a date filter on the weekly cards.

Sketch of the replacement query path (flat, in this class):

```apex
Id runningUserId = userid;
Integer year = Date.today().year();
Date yearStart = Date.newInstance(year, 1, 1);
Date today = Date.today();
Date first = today.addDays(-12 * 7);
if (today.month() == 1) {
    first = Date.newInstance(year - 1, 1, 1);
}

List<EG_Time_Card__c> timecards = [
    SELECT Id, Start_Date__c, End_Date__c, OwnerId,
           (SELECT Id, EG_Project__c, EG_Project_Task__c, Hours_Worked__c, Date__c
            FROM EG_Time_Entries__r)
    FROM EG_Time_Card__c
    WHERE OwnerId = :runningUserId
    AND Start_Date__c <= :today
    AND Start_Date__c >= :first
    ORDER BY Start_Date__c DESC
];

MetricsWrapper wrapper = new MetricsWrapper();
wrapper.complianceYear = String.valueOf(year);
// then the existing per-card hours / 40% loop, unchanged
```

Replace `wrapper.compliance` (`EG_Time_Card_Compliance__c`) with a String (or
a tiny inner class with `complianceYear` only) so the LWC does not import an
sObject you are about to delete.

`queryTimecardsByDate` already ignores the card it queries and calls
`queryTimecards(null)`, which returns empty. Leave it alone or delete it in
the same pass; the LWC does not use the live path.

### 4. `egTimesheetMetrics` LWC

Today:

```js
this.compliance = result.compliance;
this.compliance.complianceYear = this.compliance.Annual_Timecard_Compliance_Start_Date__c.substring(0,4);
```

After: bind the heading to `result.complianceYear`. The `slds-hide` score
block can be deleted with the object, or left inert. Do not keep fields that
only existed on the rollup.

### 5. Tests

They create a compliance row so a time card can be inserted. After the lookup
is gone they only need a card:

- `egTimesheet_Ctlr_Tests`
- `egTimesheetMetrics_Ctlr_Tests`
- `egEventLogicTest`

`egEventLogicTest` is not about compliance; it used the parent as a required
fixture. Once the lookup is optional-gone, drop that fixture.

## Metadata to remove (after Apex/LWC compile)

Order matters. Delete the object last.

1. Deactivate and delete flow `EG_Time_Card_Compliance_rollups`.
2. Remove `EG_Time_Card__c.EG_Time_Card_Compliance_Start_Date__c` (formula
  through the lookup) and take it off list view `Matino`.
3. Remove `EG_Time_Card__c.EG_Time_Card_Compliance__c` from the Time Card
  layout, then delete the lookup field.
4. Strip `EG_Time_Card_Compliance__c` from `User_Timesheet_Edit` (and ignore
  the two Salesforce internal extract permission sets unless you own them).
5. Delete the compliance layout, list views, and tab if any.
6. Delete object `EG_Time_Card_Compliance__c`.

Change-set / deploy rule from last time: ship the Apex/LWC/flow-off first,
validate, then the field deletes, then the object. One package that deletes
the object while Apex still references it will fail compile.

## What not to build

- No new `TimeCardComplianceService`.
- No rollup-summary fields on User. Annual score, if revived, is a query in
`egTimesheetMetrics_Ctlr` over that user's cards for the year.
- No batch that recomputes a replacement object.

## Risks

- **Reports.** Anyone filtering on Compliance Score / Mismatched Depts loses
those reports unless rebuilt on `EG_Time_Card__c`.
- **Flow volume.** The rollup currently runs on every hours change and loops
every FY card for that parent. Removing it is a performance win, not a loss.
- **January window.** Metrics currently mixes "last 12 weeks" with "all cards
on last year's compliance parent." The date-range replacement is clearer and
slightly different. Confirm with whoever owns the timesheet that last-12
weeks plus January spill into last year is the intended window.
- **Outlook Event Review** does not use this object. No change there.

## Suggested sequence in the sandbox

1. Metrics Apex + LWC + tests (page still works with the object sitting idle).
2. Batch + timesheet controller (new cards no longer get a parent).
3. Deactivate the flow.
4. Confirm timesheet and card generation in the UI.
5. Delete lookup, formula, layout, object.

Rollback until step 5 is redeploying the previous classes and reactivating the
flow. After step 5, restoring the object is a metadata undelete plus data.