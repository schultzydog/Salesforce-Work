// Sanity check for the Outlook panel match path: an event with no linked entry
// must come back with no project, and an event with one must come back ready
// to edit that entry.
List<Event> owned = [
    SELECT Id, Subject, StartDateTime
    FROM Event
    WHERE OwnerId = :UserInfo.getUserId() AND Subject != NULL
    ORDER BY StartDateTime DESC
    LIMIT 25
];
Set<String> claimed = new Set<String>();
for (EG_Time_Entry__c entry : [
    SELECT Source_Event_Id__c FROM EG_Time_Entry__c WHERE Source_Event_Id__c != NULL
]) {
    claimed.add(entry.Source_Event_Id__c);
}

for (Event e : owned) {
    String startIso = JSON.serialize(e.StartDateTime).replace('"', '');
    OutlookEventReviewController.MatchingEvent m =
        OutlookEventReviewController.findMatchingEvent(e.Subject, startIso);
    if (m == null) {
        System.debug('NO MATCH  | ' + e.Subject);
        continue;
    }
    System.debug(
        'MATCH     | ' + e.Subject +
        ' | event=' + m.id +
        ' | account=' + m.accountName +
        ' | entry=' + m.timeEntryId +
        ' | project=' + m.suggestedProjectName +
        ' | task=' + m.projectTaskName +
        ' | hours=' + m.hours +
        ' | claimed=' + claimed.contains(String.valueOf(e.Id))
    );
    if (!claimed.contains(String.valueOf(e.Id)) && m.suggestedProjectId != null) {
        System.debug('*** GUESS LEAK: project returned for an event with no linked entry ***');
    }
}
