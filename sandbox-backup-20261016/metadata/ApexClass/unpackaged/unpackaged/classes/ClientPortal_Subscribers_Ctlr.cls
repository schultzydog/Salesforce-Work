public with sharing class ClientPortal_Subscribers_Ctlr {

    @AuraEnabled
    public static List<Contact> getSubscribersApex(String searchTerm, Integer pageNumber, Integer pageSize){
        //todo: ensure running user client admin role

        List<Contact> subscribers;

        if(String.isNotBlank(searchTerm)){
            String searchWildcard = '%' + searchTerm + '%';
            subscribers = [SELECT Id, Name, Title, Email, MailingCountry,
                            Status__c, Crypto_Key__c,
                            Account.Name
                            FROM Contact 
                            WHERE //AccountId = :customerAccountId AND (controlled by sharing set)
                            (Name LIKE :searchWildcard OR
                            Email LIKE :searchWildcard) AND
                            (Status__c = 'Enabled' OR Status__c = 'Disabled' OR Status__c = NULL)
                            ORDER BY LastName, FirstName, CreatedDate                            
                            LIMIT :(pageSize+1)
                            OFFSET :((pageNumber-1)*pageSize)];
        } else {
            subscribers = [SELECT Id, Name, Title, MailingCountry, Email, 
                            Status__c, Crypto_Key__c,
                            Account.Name
                            FROM Contact 
                            WHERE //AccountId = :customerAccountId AND  (controlled by sharing set)
                            (Status__c = 'Enabled' OR Status__c = 'Disabled' OR Status__c = NULL)
                            ORDER BY LastName, FirstName, CreatedDate                            
                            LIMIT :(pageSize+1)
                            OFFSET :((pageNumber-1)*pageSize)];
        }


        system.debug('---subscribers: ' + subscribers);

        return subscribers;
    }

    @AuraEnabled
    public static List<ContactPreferencesCtlr.RootWrapper> getContactPreferencesApex(Id contactId){
        String cryptoKey = [SELECT Id, Crypto_Key__c FROM Contact WHERE Id = :contactId].Crypto_Key__c;
        return ContactPreferencesCtlr.getLibraries(cryptoKey, true, false);    
    }

    @AuraEnabled
    public static List<ContactPreferencesCtlr.RootWrapper> saveContactPreferencesApex(Id contactId, String libs){
        String cryptoKey = [SELECT Id, Crypto_Key__c FROM Contact WHERE Id = :contactId].Crypto_Key__c;
        return ContactPreferencesCtlr.saveApex(cryptoKey, libs, true);    
    }

    @AuraEnabled
    public static Contact updateContactApex(Contact contact){
        update Contact;
        return Contact;  
    }

}