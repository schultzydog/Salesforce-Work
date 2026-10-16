// Reproduces what the timesheet's project box asks for when you click into it
// with nothing typed: no search term, no filter field, no additional params.
List<SObject> results = egCustomLookup_Ctlr.searchApex('EG_Project__c', '', null, null, null);

Set<Id> ids = new Set<Id>();
for (SObject s : results) ids.add((Id) s.get('Id'));

Integer internalTrue = 0;
Integer internalFalse = 0;
for (EG_Project__c p : [SELECT Id, Name, Internal_Project__c, Is_Internal__c, Status__c
                        FROM EG_Project__c WHERE Id IN :ids]) {
    if (p.Internal_Project__c == true) internalTrue++; else internalFalse++;
}

System.debug('PROBE returned=' + results.size()
    + ' internalTrue=' + internalTrue
    + ' internalFalse=' + internalFalse);
