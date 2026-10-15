@isTest
public class ContactPrefSubscribeCtlrTests {

    static testmethod void testSubscribe() {
        
        Account a = new Account(Name='Test Account', BillingCity = 'Test', BillingCountry = 'United States');
        insert a;
        Contact c = new Contact(LastName='Test Lname',AccountId=a.Id,Email='test@abc.com',Crypto_Key__c='123');
        insert c;
        Library__c l = new Library__c(Name = 'Test Library 1',Active__c=TRUE);
        insert l;
        Account_Preferences__c aPref = new Account_Preferences__c(Account__c = a.Id, Library__c = l.Id);
        insert aPref;
        Contact_Preferences__c cPref = new Contact_Preferences__c(Account_Preferences__c = aPref.Id, Contact__c = c.Id);
        insert cPref;
        
        String success = ContactPrefSubscribeCtlr.getPref('123', l.Id);
        System.AssertEquals(success, 'Thank you for subscribing to Eurasia Group\'s Test Library 1 distribution list.');
        
        String failure = ContactPrefSubscribeCtlr.getPref('123', '123');
        System.AssertEquals(failure, 'No Contact Preference found.');
        
    }
    
}