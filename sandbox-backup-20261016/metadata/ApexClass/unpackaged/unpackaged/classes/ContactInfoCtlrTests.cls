@isTest
public class ContactInfoCtlrTests {

    static testmethod void testContactInfo() {
        Account a = new Account(Name='Test Account', BillingCity = 'Test', BillingState = 'Arizona', BillingCountry = 'United States');
        insert a;
        Contact c = new Contact(FirstName='test Fname',LastName='Test Lname',AccountId=a.Id,Email='test@abc.com',Crypto_Key__c='123');
        insert c;
        
        ContactInfoCtlr.getContact('123');
        ContactInfoCtlr.saveContact(JSON.serialize(c));
        
    }
    
}