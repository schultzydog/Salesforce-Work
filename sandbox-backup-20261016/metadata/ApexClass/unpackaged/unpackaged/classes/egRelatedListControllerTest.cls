/*
 *  Test class for findUpcomingAppearances
 * */
@isTest
private class egRelatedListControllerTest {
    
    @testSetup
    private static void makeData(){
        //Create Test Data
        Account a1 = new Account(Name='Test Account');
        insert a1;
        Contact c = new Contact(LastName='Test Lname',AccountId=a1.Id,Email='test@abc.com',Crypto_Key__c='123');
        insert c;
        Contact c2 = new Contact(LastName='Second Contact',AccountId=a1.Id,Email='contact@test.com',Crypto_Key__c='1234');
        insert c2;   
        
    }
    @isTest
    static void testController(){
        Map<String,Object> objectInfos = egRelatedListController.getObjectInfo('Contact', 'Id, Name,AccountName__c,Allspring__c,Account.Name, Account.OwnerId');
        System.assertEquals(2, objectInfos.size());
        System.assertEquals('Contacts', objectInfos.get('label'));
        System.assertEquals(6, ((List<Object>)objectInfos.get('fields')).size());

        Account a1 = [SELECT ID FROM ACcount Limit 1];

        Map<String,Object> queryResult = egRelatedListController.queryRecords('Contact', ' Name,AccountName__c,Account.Name', 'AccountId != null', 'AccountId', a1.Id, 'Name Desc');
        System.assertEquals(2, ((List<Object>)queryResult.get('data')).size());

    }




    
}