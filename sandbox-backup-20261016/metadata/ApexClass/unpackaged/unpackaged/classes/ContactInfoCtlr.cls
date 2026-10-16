public without sharing class ContactInfoCtlr {

    //public Contact contact {get;set;}
    
    public ContactInfoCtlr(ApexPages.StandardController stdController) {
        //this.contact = (Contact)stdController.getRecord();
    }
    
    @AuraEnabled
    public static Contact getContact(String key){
        
        List<Contact> cons = [SELECT Id, FirstName, LastName, Salutation, Name, Email, Phone, Account.Name, MailingStreet, 
                                MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingCountryCode, MailingStateCode 
                              FROM Contact WHERE (Crypto_Key__c =: key OR Id =: key) AND Crypto_Key__c != NULL];
        Contact con = new Contact();
        if (cons.size() > 0) {
            System.debug('Found Contact: ' + con);
            
            con = cons[0];
            
            return con;
            
        } else {
            return null;
        }
        
    }
    
    @AuraEnabled
    public static String saveContact(String contactJSON){
        
        try {
            Contact c = (Contact)JSON.deserialize(contactJSON, Contact.class);
            update c;
            return 'Saved Successfully';
        } catch(Exception e) {
            return e.getMessage();
        }
        
    }
    
}