@isTest
private class ClientPortal_Subscribers_Ctlr_Tests {

    static testmethod void testSubscribers(){
        Account a1 = new Account(Name='Test Account');
        insert a1;
        Account a2 = new Account(Name='Test Account');
        insert a2;
        Contact c = new Contact(LastName='Test Lname',AccountId=a1.Id,Email='test@abc.com');
        insert c;
        Library__c l1 = new Library__c(Name = 'Test Library', Active__c=true);
        insert l1;
        Library__c l2 = new Library__c(Name = 'Test Library', Active__c=true);
        insert l2;
        Account_Preferences__c aPref1 = new Account_Preferences__c(Account__c = a1.Id, Library__c = l1.Id);
        insert aPref1;
        Account_Preferences__c aPref2 = new Account_Preferences__c(Account__c = a1.Id, Library__c = l2.Id);
        insert aPref2;
        Account_Preferences__c aPref3 = new Account_Preferences__c(Account__c = a2.Id, Library__c = l1.Id);
        insert aPref3;
        Contact_Preferences__c cPref1 = new Contact_Preferences__c(Account_Preferences__c = aPref1.Id, Contact__c = c.Id);
        insert cPref1;
        Contact_Preferences__c cPref2 = new Contact_Preferences__c(Account_Preferences__c = aPref2.Id, Contact__c = c.Id);
        insert cPref2;
        
        c.AccountId = a2.Id;
        update c;

        Test.startTest();
        
        List<Contact> subscribersAll = ClientPortal_Subscribers_Ctlr.getSubscribersApex(null, 1, 10);
        List<Contact> subscribersSearch = ClientPortal_Subscribers_Ctlr.getSubscribersApex('Test', 1, 10);
        
        List<ContactPreferencesCtlr.RootWrapper> prefs = ClientPortal_Subscribers_Ctlr.getContactPreferencesApex(c.Id);

        //prefs = ClientPortal_Subscribers_Ctlr.saveContactPreferencesApex(c.Id, JSON.serialize(prefs[0].libs));
        
        c = ClientPortal_Subscribers_Ctlr.updateContactApex(c);
        
        Test.stopTest();
    }

}