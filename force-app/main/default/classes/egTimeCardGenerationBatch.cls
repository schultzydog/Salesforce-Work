global class egTimeCardGenerationBatch implements Database.Batchable<SObject> {

    Integer monthsAhead;

    global egTimeCardGenerationBatch() {
        monthsAhead = 3;
    }

    global egTimeCardGenerationBatch(Integer months) {
        monthsAhead = months;
    }

    global Database.QueryLocator start(Database.BatchableContext context) {

        return Database.getQueryLocator('SELECT Id, FirstName, LastName, Name, Department__c, SF_License__c FROM User where isActive = TRUE AND Timesheet_Required__c = TRUE AND SF_License__c != \'Chatter Free\'' );

    }

    global void execute(Database.BatchableContext context, List<User> scope) {
        
        Date firstCard = Date.today().toStartOfMonth().toStartOfWeek();
        Date lastCard = firstCard.addMonths(monthsAhead).toStartOfWeek();
        
        List<EG_Time_Card__c> allTimeCards = new List<EG_Time_Card__c>();
        Set<String> allExternalIds = new Set<String>();

        Set<String> deptIds = new Set<String>();
        for (User u : scope) {
            deptIds.add(u.Department__c);
        }

        List<Department__c> depts = [SELECT Id, Name FROM Department__c WHERE Name in: deptIds];

        Map<String, Department__c> deptMap = new Map<String, Department__c>();
        for (Department__c d : depts) {
            deptMap.put(d.Name, d);
        }

        for ( User u : scope ) {
            system.debug('### user license type = ' + u.SF_License__c);
            for ( Date d = firstCard; d <= lastCard; d = d.addDays(7) ) {
                
                EG_Time_Card__c tc = new EG_Time_Card__c();
                tc.OwnerId = u.Id;
                if (deptMap.containsKey(u.Department__c)) {
                    tc.Department__c = deptMap.get(u.Department__c).Id;
                }
                tc.Start_Date__c = d;
                tc.End_Date__c = d.addDays(6);
                tc.TimeCardExternalId__c = u.Id + '' + tc.Start_Date__c;
                allExternalIds.add(tc.TimeCardExternalId__c);
                tc.Name = u.Name + ': ' + tc.Start_Date__c.format() + '-' + tc.End_Date__c.format();
                allTimeCards.add(tc);
            }
            
        }
        
        List<EG_Time_Card__c> existingTimeCards = [SELECT ID, TimeCardExternalId__c FROM EG_Time_Card__c WHERE TimeCardExternalId__c in: allExternalIds];
        
        Set<String> existingExternalIds = new Set<String>();
        
        for ( EG_Time_Card__c tc : existingTimeCards ) {
            existingExternalIds.add( tc.TimeCardExternalId__c );
        }
        
        List<EG_Time_Card__c> timeCardsToInsert = new List<EG_Time_Card__c>();
        
        for ( EG_Time_Card__c tc : allTimeCards ) {
            
            if ( !existingExternalIds.contains( tc.TimeCardExternalId__c ) ) {
                timeCardsToInsert.add( tc );
            }
            
        }

        insert timeCardsToInsert;
        
    }

    global void finish(Database.BatchableContext context) {

    }

}
