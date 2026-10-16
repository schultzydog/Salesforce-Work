@isTest
public class egCustomLookup_Ctlr_Tests {

    static testmethod void testSearch() {
        
        Account a = new Account(Name='test');
        insert a;
        
        List<sObject> lookupResults = egCustomLookup_Ctlr.searchApex('Account', 'test', null, null, null);
        
        System.Assert(lookupResults != null);
        System.Assert(lookupResults.size() == 1);
        
    }
    
    static testmethod void testSearchWithParent() {
        
        Account a1 = new Account(Name='test1');
        insert a1;
        
        Account a2 = new Account(Name='test2');
        insert a2;
        
        Contact c1 = new Contact(LastName='test1', AccountId=a1.Id);
        insert c1;
        
        Contact c2 = new Contact(LastName='test2', AccountId=a2.Id);
        insert c2;
        
        List<sObject> lookupResults = egCustomLookup_Ctlr.searchApex('Contact', 'test', 'AccountId', a1.Id, null);
        
        System.Assert(lookupResults != null);
        System.Assert(lookupResults.size() == 1);

        List<sObject> lookupResults2 = egCustomLookup_Ctlr.searchApex('User', 'test', null, null, null);

        List<sObject> lookupResults3 = egCustomLookup_Ctlr.searchApex('EG_Project__c', 'test', null, null, '2024-03-03,2024-03-10');
        
    }
    
}