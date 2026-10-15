Savepoint sp = Database.setSavepoint();
try {
    KnowBe4_Module__c m = new KnowBe4_Module__c(
        Name = 'Probe Module',
        Module_External_Id__c = '999:Security Basics',
        Due_Date__c = Date.today()
    );
    insert m;

    List<KnowBe4_Module__c> byLiteral = [
        SELECT Id, Module_External_Id__c FROM KnowBe4_Module__c
        WHERE Module_External_Id__c = '999:Security Basics'
    ];
    Set<String> keys = new Set<String>{ '999:Security Basics' };
    List<KnowBe4_Module__c> byBind = [
        SELECT Id, Module_External_Id__c FROM KnowBe4_Module__c
        WHERE Module_External_Id__c IN :keys
    ];
    KnowBe4_Module__c reread = [
        SELECT Module_External_Id__c FROM KnowBe4_Module__c WHERE Id = :m.Id
    ];

    System.debug(LoggingLevel.ERROR, 'PROBE literal=' + byLiteral.size()
        + ' bind=' + byBind.size()
        + ' stored=[' + reread.Module_External_Id__c + ']');
} finally {
    Database.rollback(sp);
}
