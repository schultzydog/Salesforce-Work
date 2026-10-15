// Can an inactive user, and a CsnOnly user, own a KnowBe4 result?
Savepoint sp = Database.setSavepoint();
try {
    KnowBe4_Module__c m = new KnowBe4_Module__c(Name = 'Owner Probe', Due_Date__c = Date.today());
    insert m;

    for (String label : new List<String>{ 'inactive', 'csnonly' }) {
        List<User> candidates = label == 'inactive'
            ? [SELECT Id FROM User WHERE IsActive = false AND UserType = 'Standard' LIMIT 1]
            : [SELECT Id FROM User WHERE UserType = 'CsnOnly' LIMIT 1];
        if (candidates.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'PROBE ' + label + ' = no such user');
            continue;
        }
        try {
            insert new KnowBe4_User_Result__c(
                External_Id__c = 'probe-' + label,
                KnowBe4_Module__c = m.Id,
                User__c = candidates[0].Id,
                Status__c = 'passed'
            );
            System.debug(LoggingLevel.ERROR, 'PROBE ' + label + ' = OK');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PROBE ' + label + ' = ' + e.getMessage());
        }
    }
} finally {
    Database.rollback(sp);
}

Integer csnOnly = [SELECT COUNT() FROM User WHERE UserType = 'CsnOnly'];
Integer inactiveUsers = [SELECT COUNT() FROM User WHERE IsActive = false];
System.debug(LoggingLevel.ERROR, 'PROBE_COUNTS csnOnly=' + csnOnly + ' inactive=' + inactiveUsers);
