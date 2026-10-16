//Tests are handled by conferenceCallHandlerTest - NOT BULKIFIED
trigger confCallSpeakerTrigger on Conference_Call_Speaker__c (before insert, before update, after insert, after update) {
    
    //List<User> u = [SELECT Id, Department__c FROM User WHERE Email = :trigger.New[0].Speaker_Email__c LIMIT 1];
    List<User> u = [SELECT Id, Department__c FROM User WHERE Email = :trigger.New[0].Speaker_Email__c OR UserName = :trigger.New[0].Speaker_Email__c LIMIT 1];
    String deptname = String.valueOf(u[0].Department__c);
    List<Department__c> depts = [SELECT Id FROM Department__c WHERE Name =: deptName LIMIT 1];
    List<Conference_Call_Department__c> ccDepts = new List<Conference_Call_Department__c>();
    
    if (depts.size() > 0) ccDepts = [SELECT Id FROM Conference_Call_Department__c 
                                                    WHERE Conference_Call__c =: trigger.new[0].Conference_Call__c
                                                        AND Department__c =: depts[0].Id];
                                                        
    if (trigger.isBefore) {    
        if (u.size() > 0) trigger.new[0].Speaker_User__c = u[0].Id;
        if (depts.size() > 0) trigger.new[0].Department__c = depts[0].Id;
    } 

    if (trigger.isAfter) {
        if (depts.size() > 0 && (ccDepts.size() == 0 || ccDepts == null)) {
            system.debug('### after trigger = ' + depts );
            Conference_Call_Department__c ccDept = new Conference_Call_Department__c(Conference_Call__c = trigger.new[0].Conference_Call__c,
                Department__c = depts[0].Id);
            insert ccDept;
        }

    }
}