// Saves the timesheet for a week that holds an Event-linked entry and checks
// the entry is still there afterwards. Before the Source_Event_Id__c filter on
// the delete sweep, the save removed it: the grid cannot regenerate a key that
// carries the event, so the entry looked like a row the user had cleared.
Id entryId = 'a30WL000008iK9hYAE';

EG_Time_Entry__c before = [
    SELECT Id, EG_Time_Card__c, Date__c, EG_Time_Card__r.OwnerId, ExternalID__c
    FROM EG_Time_Entry__c WHERE Id = :entryId
];

egTimesheet_Ctlr.TimesheetWrapper wrapper =
    egTimesheet_Ctlr.getTimesheetForDateApex(before.Date__c, before.EG_Time_Card__r.OwnerId, false);

egTimesheet_Ctlr.saveTimesheetApex(
    wrapper.timeCardId,
    before.EG_Time_Card__r.OwnerId,
    wrapper.startDate,
    wrapper.rows,
    new List<String>{ null, null, null, null, null }
);

Integer survived = [SELECT COUNT() FROM EG_Time_Entry__c WHERE Id = :entryId];
System.debug('PROBE survived=' + survived + ' (expected 1)');
