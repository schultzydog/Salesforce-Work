public without sharing class ClientPortal_RequestForm_Ctlr {

    @AuraEnabled(cacheable=true)
    public static Library__c getPageDataApex(String libraryId){
        //NOTE: without sharing class
        
        if(String.isNotBlank(libraryId)){
            List<Library__c> libraries = [SELECT Id, Name FROM Library__c WHERE Id = :libraryId]; //Limit fields to public-safe disclosure
            if(libraries!=null && !libraries.isEmpty()){
                Library__c library = libraries[0];
                return library;
            } else {
                throw new AuraHandledException('Invalid request parameters. Please include the link parameters or contact your account administrator so your request can be added.');
            }
        } else {
            throw new AuraHandledException('Invalid request parameters. Please include the link parameters or contact your account administrator so your request can be added.');
        }
    }

    @AuraEnabled
    public static Lead saveLeadApex(Lead lead){
        //NOTE: without sharing class

        //Check for non-allowed personal email domains...
        Set<String> personalEmailDomains = new Set<String>{'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'}; //put this in some declarative structure? 
        String leadEmailDomain = lead.Email.split('@')[1].toLowerCase();
        if(personalEmailDomains.contains(leadEmailDomain)){
            throw new AuraHandledException('This email domain has not been approved for your company. Please use a company email address or contact your account administrator so your request can be added.');
        }

        try{
            List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE Email = :lead.Email ORDER BY LastModifiedDate DESC];
            List<Contact> contacts = [SELECT Id, OwnerId FROM Contact WHERE Email = :lead.Email ORDER BY LastModifiedDate DESC];

            if(leads.isEmpty() && contacts.isEmpty()){
                //Create a new Lead...

                //Get Client Services Queue for Lead Owner...
                List<Group> clientServicesQueues = [SELECT DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Client_Services'];
                if(clientServicesQueues.size()==1){
                    lead.OwnerId = clientServicesQueues[0].Id;
                }

                //Changed to comment out recordtype assignment. Do not assign, per Adam, 12/1/2022 bry
                //Get Company Referral recordtype Id...
                //Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Company_Referral').getRecordTypeId();
                //Set Lead record type to Company Referral...
                //lead.RecordTypeId = leadRecordTypeId;

                //try insert lead...
                insert lead;

                leads = new List<Lead>{lead};
            }

            if(!leads.isEmpty() || !contacts.isEmpty()){
                //create a new Task for one of the contacts or leads...                
                Id taskWhoId = null;
                Id taskOwnerId = null;
                String additionalMatchIds = '';
                if(!contacts.isEmpty()){
                    Contact primaryContact = contacts.remove(0);
                    taskWhoId = primaryContact.Id;
                    taskOwnerId = primaryContact.OwnerId;
                    for(Contact c : contacts){
                        additionalMatchIds += c.Id + ',';
                    }
                    for(Lead l : leads){
                        additionalMatchIds += l.Id + ',';
                    }       
                    if(additionalMatchIds.endsWith(',')){
                        additionalMatchIds = additionalMatchIds.left(additionalMatchIds.length()-1);
                    }             
                } else if(!leads.isEmpty()){
                    Lead primaryLead = leads.remove(0);
                    taskWhoId = primaryLead.Id;
                    taskOwnerId = primaryLead.OwnerId;
                    for(Lead l : leads){
                        additionalMatchIds += l.Id + ',';
                    }       
                    if(additionalMatchIds.endsWith(',')){
                        additionalMatchIds = additionalMatchIds.left(additionalMatchIds.length()-1);
                    }    
                }

                if(taskWhoId!=null){
                    Task taskToInsert = new Task();
                    taskToInsert.ActivityDate = Date.today().addDays(7); //changed from 5 to 7, per Adam 12/1/2022 bry
                    taskToInsert.Description = (lead.Description + ((String.isNotBlank(additionalMatchIds) ? ('. *** EMAIL DUPLICATES FOUND AT ' + additionalMatchIds + ' ***') : ''))).left(32000);
                    taskToInsert.OwnerId = taskOwnerId;
                    taskToInsert.Status = 'Open';
                    taskToInsert.Subject = (lead.Description + ((String.isNotBlank(additionalMatchIds) ? ('. *** EMAIL DUPLICATES FOUND (SEE DESCRIPTION FOR IDS) ***') : ''))).left(255);
                    taskToInsert.Type = 'To Do';
                    taskToInsert.TaskSubtype = 'Task';
                    taskToInsert.WhoId = taskWhoId;

                    insert taskToInsert;
                }
            }
        } catch(Exception e){
            //Default Error Log content (all non-specific errors)...
            String errorSource = 'Request Form';
            String errorRecordId = 'New Lead';
            String errorMessage = e.getMessage();
            String errorStackTrace = String.valueOf(lead);

            system.debug('----- error: ' + errorMessage);
            if(String.isNotBlank(errorMessage) && errorMessage.contains('Lead with this email address already exists')){
                //Duplicate Lead - Find Lead record and add Error Log with Lead data entry details...
                errorRecordId = 'Existing Lead';
                List<Lead> existingLeads = [SELECT Id FROM Lead WHERE Email = :lead.Email ORDER BY CreatedDate DESC LIMIT 1];
                if(existingLeads!=null && !existingLeads.isEmpty()){
                    errorRecordId = existingLeads[0].Id;
                }
            } else if(String.isNotBlank(errorMessage) && errorMessage.contains('Contact with this email address already exists')){
                //Duplicate Contact - Find Contact record and add Error Log with Lead data entry details...
                errorRecordId = 'Existing Contact';
                List<Contact> existingContacts = [SELECT Id FROM Contact WHERE Email = :lead.Email ORDER BY CreatedDate DESC LIMIT 1];
                if(existingContacts!=null && !existingContacts.isEmpty()){
                    errorRecordId = existingContacts[0].Id;
                }
            }

            //Add Error Log record...
            Error_Log__c errorLog = new Error_Log__c(
                Source__c = errorSource,
                Record_ID__c = errorRecordId,
                Stack_Trace__c = errorStackTrace,
                Error_Message__c = errorMessage
            );
            insert errorLog;

            //Adding Chatter record not possible with Guest User
        }

        return lead;
    }
}