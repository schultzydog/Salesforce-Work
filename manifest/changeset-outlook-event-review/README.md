# Change set: Outlook Event Review panel

Salesforce outbound change sets are built in **Setup in the sandbox**, not from
these XML files. The package files here are the **component checklist**.

## Hard constraint

Change sets pull whatever is **currently deployed in EG-Sandbox**.

The sweeping External ID work (fifth part = Event Id) and the timesheet rework
are already live in that sandbox on some of the same Apex classes the panel
uses. You **cannot** put `OutlookEventReviewController` / `TimeEntryService` /
`TimeEntryKey` into a change set from this org without also shipping the
fifth-part key logic that is in those classes today.

| Goal | Use |
| --- | --- |
| Title + sticky headers only, zero Apex risk | `package-ui-only.xml` |
| Full panel + Event Review Apex as in sandbox now | `package.xml` (includes fifth-part External ID) |
| Full panel Apex **without** fifth-part key | Redeploy carved 4-part Apex first, then build change set — ask before doing this |

## Do not add (manager approval pending)

- `egTimesheet_Ctlr`, `egTimesheet` LWC, `egTimesheet_Ctlr_Tests`
- `egEventLogic`, `EventTrigger`
- `EG_Time_Entry__c.Start_Time__c`
- `blogic_Event`
- Anonymous Apex scripts (run manually in prod when ready)

## How to build the outbound change set in EG-Sandbox

1. Setup → **Outbound Change Sets** → **New**
2. Name: `Outlook Event Review Panel` (or similar)
3. Description: what this ships / what it deliberately excludes
4. **Add** → pick the members from the checklist below
5. Upload → deploy inbound in production (Austin)

### Checklist A — UI only (`package-ui-only.xml`)

- [ ] Lightning Component Bundle: `egOutlookEventReview`
- [ ] Tab: `Outlook_Event_Review`
- [ ] Lightning Page: `Outlook_Event_Review`

### Checklist B — full panel as currently in sandbox (`package.xml`)

**Lightning**

- [ ] `egOutlookEventReview`
- [ ] `outlookTimeEntry`
- [ ] `egCustomLookup`

**Tab / page**

- [ ] Tab `Outlook_Event_Review`
- [ ] FlexiPage `Outlook_Event_Review`

**Apex**

- [ ] `OutlookEventReviewController` + `OutlookEventReviewControllerTest`
- [ ] `TimeEntryController` + `TimeEntryControllerTest`
- [ ] `TimeEntryService` + `TimeEntryServiceTest`
- [ ] `TimeEntryRequest`
- [ ] `TimeEntryKey` + `TimeEntryKeyTest`
- [ ] `TimeEntrySelector`, `TimeEntrySummary`
- [ ] `TimeCardSelector` + `TimeCardSelectorTest`
- [ ] `ProjectSelector`, `ProjectTaskSelector`
- [ ] `egCustomLookup_Ctlr` + `egCustomLookup_Ctlr_Tests`

**Data model / access**

- [ ] Field `EG_Time_Entry__c.Source_Event_Id__c`
- [ ] Field `EG_Time_Entry__c.Time_Entry_Source__c`
- [ ] Permission set `Outlook_Time_Entry_User`
- [ ] Layout `EG Time Entry Layout` (if prod layout is missing the source fields)

### After deploy in production (Checklist B)

1. Assign `Outlook_Time_Entry_User` to the right users if not already.
2. Run `scripts/apex/migrate-event-entry-link.apex` **only if** prod still has
   `Activity.EG_Time_Entry__c` and you need links moved onto `Source_Event_Id__c`.
3. Do **not** run `backfill-event-entry-key.apex` unless the fifth-part key
   change is intentionally going live (that script is for the sweeping work).

## Recommended path given manager approval is pending

Use **Checklist A (UI only)** now for title + sticky headers.

Hold Checklist B until either:

- the External ID / timesheet work is approved, or
- we carve fifth-part key usage out of the panel Apex in sandbox, redeploy that
  thinner build, then build Checklist B from the org.
