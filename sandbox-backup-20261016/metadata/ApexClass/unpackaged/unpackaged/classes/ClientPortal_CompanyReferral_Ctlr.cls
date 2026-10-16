public without sharing class ClientPortal_CompanyReferral_Ctlr {
    
    @AuraEnabled(cacheable=true)
    public static Account getCompanyFromReferralKeyApex(String recordLocator){
        //NOTE: without sharing class
        
        if(String.isNotBlank(recordLocator)){
            List<Account> companies = [SELECT Id, Name, OwnerId, Company_Logo_URL__c FROM Account WHERE Record_Locator__c = :recordLocator]; //Limit fields company-safe
            if(companies!=null && !companies.isEmpty()){
                Account company = companies[0];
                return company;
            } else {
                throw new AuraHandledException('Invalid referral source');
            }
        } else {
            throw new AuraHandledException('Invalid referral source');
        }
    }

    @AuraEnabled
    public static Lead saveLeadApex(Lead lead){
        //NOTE: without sharing class

        //Check for non-allowed personal email domains...
        Set<String> personalEmailDomains = new Set<String>{'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'}; 
        //  put this in some declarative structure?        
        String leadEmailDomain = lead.Email.split('@')[1].toLowerCase();
        if(personalEmailDomains.contains(leadEmailDomain)){
            throw new AuraHandledException('This email domain has not been approved for your company. Please use a company email address or contact your account administrator so your request can be added.');
        }

        //Check for email domain must already be under account...
        List<Contact> existingEmailDomainContacts = [SELECT Email_Domain__c FROM Contact WHERE AccountId = :lead.Company_Referral_Account_Id__c]; 
        //  Email Domain is currently formula which prevents GROUP BY efficiencies, different approach? How many contacts under 1 account?
        Set<String> existingEmailDomains = new Set<String>();
        for(Contact c : existingEmailDomainContacts){
            existingEmailDomains.add(c.Email_Domain__c);
        }
        if(!existingEmailDomains.contains(leadEmailDomain)){
            throw new AuraHandledException('This email domain has not been approved for your company. Please use an approved company email address or contact your account administrator so your request can be added.');
        }

        try{
            //Get Company Referral recordtype Id...
            Id leadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Company_Referral').getRecordTypeId();
            
            //Set Lead record type to Company Referral...
            lead.RecordTypeId = leadRecordTypeId;

            //try insert lead...
            insert lead;

            //Insert a task on the new lead...
            insert getTaskToInsert(lead);
        } catch(Exception e){
            //Default Error Log content (all non-specific errors)...
            String errorSource = 'EG Update Company Referral Form';
            String errorRecordId = 'New Lead';
            String errorMessage = e.getMessage();
            String errorStackTrace = String.valueOf(lead);

            system.debug('----- error: ' + errorMessage);
            if(String.isNotBlank(errorMessage) && errorMessage.contains('Lead with this email address already exists')){
                //Duplicate Lead - Find Lead record and add Error Log with Lead data entry details...
                errorRecordId = 'Existing Lead';
                List<Lead> existingLeads = [SELECT Id, OwnerId FROM Lead WHERE Email = :lead.Email ORDER BY CreatedDate DESC LIMIT 1];
                if(existingLeads!=null && !existingLeads.isEmpty()){
                    errorRecordId = existingLeads[0].Id;

                    //Insert a task on the existing lead...
                    insert getTaskToInsert(existingLeads[0]);
                }
            } else if(String.isNotBlank(errorMessage) && errorMessage.contains('Contact with this email address already exists')){
                //Duplicate Contact - Find Contact record and add Error Log with Lead data entry details...
                errorRecordId = 'Existing Contact';
                List<Contact> existingContacts = [SELECT Id, OwnerId FROM Contact WHERE Email = :lead.Email ORDER BY CreatedDate DESC LIMIT 1];
                if(existingContacts!=null && !existingContacts.isEmpty()){
                    errorRecordId = existingContacts[0].Id;

                    //Insert a task on the existing contact...
                    insert getTaskToInsert(existingContacts[0]);
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

    private static Task getTaskToInsert(SObject who){
        //create a new Task for the who object (a contact or lead)...                

        String whoType = who.Id.getSObjectType().getDescribe().getName();

        Task taskToInsert = new Task();
        taskToInsert.WhoId = who.Id;
        taskToInsert.OwnerId = (Id)who.get('OwnerId');
        taskToInsert.Subject = (whoType=='Contact') ? 
                                'Company User Registration Request' :
                                'Company User Registration Request';
        taskToInsert.Description = (whoType=='Contact') ? 
                                    'This contact submitted a Company User Registration request to be added to research distribution.' :
                                    'This lead submitted a Company User Registration request to be added to research distribution. Please convert to "Enabled" contact if desired. Otherwise convert to "Disabled" contact.';
        taskToInsert.Status = 'Open';
        taskToInsert.ActivityDate = Date.today().addDays(7);
        taskToInsert.Type = 'To Do';
        taskToInsert.TaskSubtype = 'Task';

        return taskToInsert;
    }
    
}