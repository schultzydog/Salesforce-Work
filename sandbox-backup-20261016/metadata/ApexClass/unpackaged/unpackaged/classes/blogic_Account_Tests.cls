@isTest
private class blogic_Account_Tests {

    static testmethod void testAccountTriggerLogic(){
        //todo: create runAs user
        Test.startTest();
        Account a = new Account(Name='Test Account');
        insert a;
        //a.Trigger_Contact_Rollups__c = true;
        update a;
        Test.stopTest();
    }
}