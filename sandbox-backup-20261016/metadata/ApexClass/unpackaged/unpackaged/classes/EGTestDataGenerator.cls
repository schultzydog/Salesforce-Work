/**
 *  This class use EGTestDataFactory and generate Test data for sObjects
 */

 @isTest
 public class EGTestDataGenerator {
     public static User getTestUser(){
         List<sObject> users = EGTestDataFactory.createSObjectList('User', new Map<String,Object>{
             'ProfileId' => UserInfo.getProfileId()
           }, 1, false);
 
           return (User)users[0];
     }
 
 
     public static List<Account> getAccounts(){
         List<Account> accList = EGTestDataFactory.createSObjectList('Account',5);
         return accList;
     }
 
 
     public static List<Contact> getContacts(List<Account> accounts){
         List<sObject> contacts = new List<sObject>();
         for(Account acc : accounts){
             contacts.addAll(
                 EGTestDataFactory.createSObjectList('Contact', new Map<String,Object>{'AccountId' => acc.Id}, 5, false)
             );
         }
         insert contacts;
         return contacts;
     }

     public static List<Morning_Meeting_Note__c> getMMNotes(String email){
        List<Morning_Meeting_Note__c> notes = EGTestDataFactory.createSObjectList('Morning_Meeting_Note__c', new Map<String,Object>{'Submitted_by_Email__c' => email}, 1, false);
        return notes;
     }
 
 
 }