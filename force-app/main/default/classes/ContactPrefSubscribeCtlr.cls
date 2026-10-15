public without sharing class ContactPrefSubscribeCtlr {

    @AuraEnabled
    public static String getPref(String key, String library){
        
        //allow standard sfdc id: List<Contact_Preferences__c> prefs = [SELECT Id, Name, Account_Preferences__r.Library__r.Name FROM Contact_Preferences__c WHERE (Contact__r.Crypto_Key__c =: key OR Contact__c = :key) AND Account_Preferences__r.Library__c =: library];
        //only allow crypto key: List<Contact_Preferences__c> prefs = [SELECT Id, Name, Account_Preferences__r.Library__r.Name FROM Contact_Preferences__c WHERE Contact__r.Crypto_Key__c =: key AND Account_Preferences__r.Library__c =: library];
        List<Contact_Preferences__c> prefs = [SELECT Id, Name, Account_Preferences__r.Library__r.Name FROM Contact_Preferences__c WHERE Contact__r.Crypto_Key__c =: key AND Account_Preferences__r.Library__c =: library];

        if (prefs.size() > 0) {
            Contact_Preferences__c pref = prefs[0];
            pref.Trial__c = false;
            update pref;
            
            return 'Thank you for subscribing to Eurasia Group\'s '+pref.Account_Preferences__r.Library__r.Name+' distribution list.';
        }        
        return 'No Contact Preference found.';
        
    }
    
}