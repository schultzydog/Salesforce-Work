/**
 * @description       : Trigger handler for Contact
**/
public class blogic_Contact {

    public static void updateContactPreferences(Map<Id, Contact> oldMap, Map<Id, Contact> newMap){
        
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> libraryIds = new Set<Id>();
        
        for (Contact c : newMap.values()) {
            
            if (c.AccountId != oldMap.get(c.Id).AccountId){
                
                if (c.AccountId != null){
                    contactIds.add(c.Id);
                    accountIds.add(c.AccountId);
                }               
            }    
        }
        
        if (contactIds.size() == 0) return;
        
        List<Contact_Preferences__c> conPrefs = [SELECT Id, Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.OwnerId, Contact__r.Owner.Email, Contact__r.AccountId, Account_Preferences__r.Library__c FROM Contact_Preferences__c WHERE Contact__c in: contactIds];
        List<Account_Preferences__c> accPrefs = [SELECT Id, Account__c, Library__c FROM Account_Preferences__c WHERE Account__c in: accountIds];
        
        Map<String, Account_Preferences__c> accPrefMap = new Map<String, Account_Preferences__c>();

        for (Account_Preferences__c aPref: accPrefs){
            
            String key = aPref.Account__c+'|'+aPref.Library__c;
            accPrefMap.put(key, aPref);
            
        }
        
        List<Contact_Preferences__c> conPrefsToUpdate = new List<Contact_Preferences__c>();
        Map<Id, Map<Id, List<Contact_Preferences__c>>> ownerMap = new Map<Id, Map<Id, List<Contact_Preferences__c>>>();
        
        Set<Id> conIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        
        for (Contact_Preferences__c cPref : conPrefs){
            String key = cPref.Contact__r.AccountId+'|'+cPref.Account_Preferences__r.Library__c;
            
            if (accPrefMap.containsKey(key)){
                //Update conPrefs
                
                System.debug('### Updating Con Pref to: ' + accPrefMap.get(key));
                cPref.Account_Preferences__c = accPrefMap.get(key).Id;
                conPrefsToUpdate.add(cPref);
                
            } else {
                //Uncheck conPrefs and flag for deletion
                
                System.debug('### Deleting Con Pref: ' + cPref);
                cPref.Flag_for_Deletion__c = true;
                cPref.Individual_Emails__c = false;
                cPref.Summary_Emails__c = false;
                
                conPrefsToUpdate.add(cPref);
                
                conIds.add(cPref.Contact__c);
                userIds.add(cPref.Contact__r.OwnerId);
                
                if (ownerMap.containsKey(cPref.Contact__r.OwnerId)){
                    Id conId = cPref.Contact__c;
                    
                    if (ownerMap.get(cPref.Contact__r.OwnerId).containsKey(conId)){
                        ownerMap.get(cPref.Contact__r.OwnerId).get(conId).add(cPref);
                    } else {
                        ownerMap.get(cPref.Contact__r.OwnerId).put(conId, new List<Contact_Preferences__c>{cPref});
                    }
                    
                } else {
                    Id conId = cPref.Contact__c;
                    ownerMap.put(cPref.Contact__r.OwnerId, new Map<Id, List<Contact_Preferences__c>>());
                    ownerMap.get(cPref.Contact__r.OwnerId).put(conId, new List<Contact_Preferences__c>{cPref});
                    
                }               
            }           
        }
        
        if (conPrefsToUpdate.size() > 0){
            try{
                update conPrefsToUpdate;
            } catch(Exception e){
                System.debug('ERROR: ' + e.getMessage());
                throw e;
            }
        }
        
        if (conIds.size() == 0) return;
        
        Map<Id, Contact> conMap = new Map<Id, Contact>( [SELECT Id, Name, Email, AccountId,  Account.Name FROM Contact WHERE Id in: conIds] );
        Map<Id, User> userMap = new Map<Id, User>( [SELECT Id, Name, Email FROM User WHERE Id in: userIds] );

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Id ownerId : ownerMap.keySet()){
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            email.setTargetObjectId(ownerId);
            email.setSubject('Contact Account Change');
            email.saveAsActivity = false;
            String textBody = 'The following Contacts have changed Accounts:\n\n';
            String htmlBody = '<p>The following Contacts have changed Accounts:</p><ul>';
            
            for (Id contactId : ownerMap.get(ownerId).keySet()){
                
                textBody += 'Contact: ' + conMap.get(contactId).Name + ', Account: ' + conMap.get(contactId).Account.Name +'\n\n';
                htmlBody += '<li>Contact: <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/' + contactId+'">' + conMap.get(contactId).Name + '</a> has changed from <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+ oldMap.get(contactId).AccountId + '">' + oldMap.get(contactId).AccountName__c + '</a> to <a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+conMap.get(contactId).AccountId+'">' + conMap.get(contactId).Account.Name + '</a>';
                
                textBody += 'The following Contact Preferences are no longer valid and have been flagged for deletion:\n';
                htmlBody += '<ul>The following Contact Preferences are no longer valid and have been flagged for deletion:';
                for (Contact_Preferences__c cp : ownerMap.get(ownerId).get(contactId)){
                    
                    textBody += 'cPref: ' + cp + '\n';
                    htmlBody += '<li><a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+cp.id+'">'+cp.Name+'</a></li>';
                    
                }
                
                textBody += '\n\n';
                htmlBody += '</ul>';
            }
            htmlBody += '</ul>';
            
            System.debug('HTML: ' + htmlBody);
            
            email.setPlainTextBody(textBody);
            email.setHTMLBody(htmlBody);
            emails.add(email);
        }
        
        Messaging.sendEmail( emails );
        
    }
   
    
    public static void createNewExternalId(List<Contact> contacts) {         
        
        //List<Contact> needGUIDs = [SELECT Id, Crypto_Key__c FROM Contact WHERE Id IN: conIds];
        for(Contact con : contacts){
            if(con.Crypto_Key__c == null) con.Crypto_Key__c = getOneGuid('contact');             
            system.debug('### con.Crypto_Key__c = ' + con.Crypto_Key__c);
        }      
    }
    
    public static void preventContactDupes(List<Contact> contacts, Map<Id, Contact> oldMap) {         
        Map<String, Contact> emailMap = new Map<String, Contact>();
        
        for (Contact c : contacts) {     
            system.debug('### c.Email = ' + c.Email);
            if (oldMap != null && oldMap.get(c.Id) != null) 
            system.debug('### oldMap.get(c.Id).Email = ' + oldMap.get(c.Id).Email);
            
            if ((c.Email != null) && (System.Trigger.isInsert || (c.Email != oldMap.get(c.Id).Email))) {
                if(emailMap.containsKey(c.Email)) {
                 
                    c.Email.addError('Contact has the same Email address');
                } else {
                    emailMap.put(c.Email, c);
                }
            }                 
        }
        system.debug('### emailMap = ' + emailMap.KeySet());
        for (Contact c : [SELECT Email FROM Contact WHERE Email IN :emailMap.KeySet() AND Email != 'japan@eurasiagroup.net' AND Email != 'Research-Invoicing@amundi.com']) {
            //system.debug('### C.email= ' +   C.email);    
            Contact c1 = emailMap.get(c.Email); 
            //system.debug('### Contact c1= ' + c1 );           
            c1.Email.addError('Contact with this email address already exists');

        }   
    }    

    public static String getOneGuid(String objectType) {
        Blob binaryString = Crypto.GenerateAESKey(192);
        String base64String = EncodingUtil.base64Encode(binaryString);
        String guid = base64String.replace('+','p').replace('/','s').replace('=','');
        /*
        Integer count = database.countQuery('SELECT COUNT() FROM ' + objectType + ' WHERE Crypto_Key__c = \'' + guid + '\'');
        while(count != 0){ //try again until unique...
            binaryString = Crypto.GenerateAESKey(192);
            base64String = EncodingUtil.base64Encode(binaryString);
            guid = base64String.replace('+','p').replace('/','s').replace('=','');
            count = database.countQuery('SELECT COUNT() FROM ' + objectType + ' WHERE Crypto_Key__c = \'' + guid + '\'');
        }
        */
        return guid;
    }    
 /*   
    public static void setOwnerForContactsCreatedFromClientPortal(List<Contact> contacts) {         
        //expecting BEFORE INSERT trigger context

        try{ //this is for new Client Portal, if it fails, don't let it stop production saves
            system.debug('--- setOwnerForContactsCreatedFromClientPortal START');
            system.debug('--- contacts pre: ' + contacts);

            User runningUser = [SELECT Id, Profile.Name, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];
            Boolean runningUserIsClientPortalUser = (runningUser.Profile.Name=='Client Portal (External)');
            system.debug('--- runningUser: ' + runningUser);
            system.debug('--- runningUserIsClientPortalUser: ' + runningUserIsClientPortalUser);

            List<Contact> contactsCreatedFromClientPortal = new List<Contact>();
            for(Contact c : contacts){
                if(runningUserIsClientPortalUser && c.CreatedById==null){
                    c.AccountId = runningUser.Contact.AccountId; //make sure contact's created from Client Portal have same Account as Client Portal admin (running user)
                    contactsCreatedFromClientPortal.add(c);
                }
            }
    
            if(!contactsCreatedFromClientPortal.isEmpty()){
                Set<Id> accountIds = new Set<Id>();
                for(Contact c : contactsCreatedFromClientPortal){
                    if(c.AccountId!=null) accountIds.add(c.AccountId);
                }
    
                Map<Id, Account> mapAccounts = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN :accountIds]);
    
                for(Contact c : contactsCreatedFromClientPortal){
                    system.debug('--- contactCreatedFromClientPortal pre: ' + c.FirstName + ' ' + c.LastName + ', OwnerId: ' + c.OwnerId);       
                    c.OwnerId = mapAccounts.get(c.AccountId).OwnerId;
                    system.debug('--- contactCreatedFromClientPortal post: ' + c.FirstName + ' ' + c.LastName + ', OwnerId: ' + c.OwnerId);       
                }
            }

            system.debug('--- contacts contactsCreatedFromClientPortal: ' + contactsCreatedFromClientPortal);
            system.debug('--- contacts post: ' + contacts);
        } catch (Exception e){
            system.debug('--- Exception: ' + e.getStackTraceString());
        }

        system.debug('--- setOwnerForContactsCreatedFromClientPortal FINISH');
        //No DML because BEFORE INSERT context
    }
  */  
    
    @future(callout=true)
    public static void toolingcallouts(){
    
        String jsonPrep;
        String jsonPrepCustomValues = '';
        String jsonPrepFirstPiece = '{"Metadata":{"customValue":[';
        String jsonPrepSecondPiece = '{"color":null,"default":false,"description":null,"isActive":null, "label":"';
        String jsonPrepInnerPiece = '"urls":null, "valueName":"';
        String jsonPrepLastPiece = '"description":null,"masterLabel":"Analyst","sorted":false,"urls":null},"FullName":"Analyst__gvs"}';    

        //Map<String,String> analystEmails = new Map<String,String>();
            
        for (Contact c: [SELECT Email, Name FROM Contact WHERE Include_in_Analyst_picklist_value_set__c = true ORDER BY Name ASC NULLS FIRST ]) {
            jsonPrepCustomValues = jsonPrepCustomValues + jsonPrepSecondPiece + c.Name + '",'+ jsonPrepInnerPiece + c.Email + '"},';
            //analystEmails.put(user.Name, user.Username);       
        }   
    
        jsonPrep = jsonPrepFirstPiece + jsonPrepCustomValues ;
        jsonPrep = jsonPrep.removeEnd(',');
        jsonPrep = jsonPrep + '],';
        jsonPrep = jsonPrep + jsonPrepLastPiece;
    
        System.debug('### jsonPrep =' + jsonPrep );      
 
        HttpRequest reqt = new HttpRequest();
        reqt.setBody(jsonPrep);
        reqt.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        reqt.setHeader('Content-Type', 'application/json');      
        reqt.setEndpoint(System.Url.getOrgDomainUrl().toExternalForm()+'/services/data/v60.0/tooling/sobjects/GlobalValueSet/0Nt3A000000L3mi?_HttpMethod=PATCH');
        reqt.setMethod('PATCH');
        reqt.setTimeout(60 * 1000);
        Http httpreq = new Http();
        HttpResponse httpres  = httpreq.send(reqt);
        system.debug('### httpres '+httpres);
    }    

}