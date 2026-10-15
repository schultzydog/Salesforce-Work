// Moves the Event-to-entry link off Activity.EG_Time_Entry__c and onto
// EG_Time_Entry__c.Source_Event_Id__c so the field can be deleted. Safe to
// re-run: entries that already carry the right key are skipped.
Map<Id, EG_Time_Entry__c> toStamp = new Map<Id, EG_Time_Entry__c>();
Integer alreadyCorrect = 0;
Integer conflicts = 0;

Map<Id, Id> eventByEntry = new Map<Id, Id>();
for (Event e : [
    SELECT Id, EG_Time_Entry__c, EG_Time_Entry__r.Source_Event_Id__c
    FROM Event
    WHERE EG_Time_Entry__c != NULL
]) {
    Id entryId = e.EG_Time_Entry__c;
    if (eventByEntry.containsKey(entryId)) {
        // Two events pointing at one entry: the entry can only claim one.
        conflicts++;
        System.debug('CONFLICT | entry ' + entryId + ' claimed by ' + eventByEntry.get(entryId) + ' and ' + e.Id);
        continue;
    }
    eventByEntry.put(entryId, e.Id);

    if (e.EG_Time_Entry__r.Source_Event_Id__c == String.valueOf(e.Id)) {
        alreadyCorrect++;
        continue;
    }
    toStamp.put(entryId, new EG_Time_Entry__c(
        Id = entryId,
        Source_Event_Id__c = String.valueOf(e.Id)
    ));
}

System.debug('Linked events found : ' + eventByEntry.size());
System.debug('Already stamped     : ' + alreadyCorrect);
System.debug('Conflicts skipped   : ' + conflicts);
System.debug('To stamp            : ' + toStamp.size());

if (!toStamp.isEmpty()) {
    update toStamp.values();
    System.debug('Stamped ' + toStamp.size() + ' entries.');
}
