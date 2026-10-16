/**
 * @description       : Account Trigger handler
**/
public without sharing class blogic_Account {
    //Centralize all Account Trigger business logic in blogic_Account class
    // NOTE: This class runs "without sharing" per standard for all business logic trigger logic classes
    
    public static void createNewExternalId(List<Account> accounts) {         
        //generate a random key as an External Id to be used for public pages where we do not want to expose Salesforcey Ids (Bryan 4/23/2022)
        for(Account acct : accounts){
            if(String.isBlank(acct.Crypto_Key__c)){
                acct.Crypto_Key__c = blogic_Contact.getOneGuid('Account'); //use existing generate key logic in blogic_Contact class
            }             
        }          
        //Expecting "before" trigger context, no DML needed
    }
/*
    public static void triggerContactRollup(Map<Id, Account> oldMap, Map<Id, Account> newMap){
        //AccontIds for manual trigger contact rollup
        Set<Id> accountIds = new Set<Id>();
        //Find account where Trigger_Contact_Rollups__c is changed to true
        for(Account acc : newMap.values()){
            //Only if Trigger_Contact_Rollups__c is changed to true
            if(acc.Trigger_Contact_Rollups__c == true && oldMap.get(acc.Id).Trigger_Contact_Rollups__c != true){
                accountIds.add(acc.Id);
            }
        }

        //Trigger Contact rollup
        if(! accountIds.isEmpty()){
            blogic_Contact.rollupToAccount(accountIds);
        }
    }
    */
}