# Feature 1 change set — Event Id save (Event Review)

Add these to an outbound change set from EG-Sandbox:

1. Apex Class → `OutlookEventReviewController`
2. Apex Class → `OutlookEventReviewControllerTest`
3. Custom Field → `EG_Time_Entry__c.Source_Event_Id__c`
4. Permission Set → `Outlook_Time_Entry_User`
5. Lightning Component Bundle → `egOutlookEventReview` *(if UI not already in prod)*
6. Tab → `Outlook_Event_Review` *(if not already in prod)*
7. Lightning Page → `Outlook_Event_Review` *(if not already in prod)*

Do **not** add for this feature: `TimeEntryKey`, `TimeEntryService`, timesheet classes, `egEventLogic`, `EventTrigger`, `Start_Time__c`.
