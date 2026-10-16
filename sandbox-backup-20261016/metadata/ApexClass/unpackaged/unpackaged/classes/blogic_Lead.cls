public class blogic_Lead {

    public static void preventLeadDupes(List<Lead> leads, Map<Id, Lead> oldMap) {         
        Map<String, Lead> emailMap = new Map<String, Lead>();
        
        for (Lead l : leads) {
            if ((l.Email != null) && (System.Trigger.isInsert || (l.Email != oldMap.get(l.Id).Email))) {
                if(emailMap.containsKey(l.Email)) {
                    l.Email.addError('Lead has the same Email address');
                } else {
                    emailMap.put(l.Email, l);
                }
            }                 
        }
    
        for (Lead l : [SELECT Email FROM Lead WHERE Email IN :emailMap.KeySet()]) {
            Lead c1 = emailMap.get(l.Email);            
            c1.Email.addError('Lead with this email address already exists');
        }   
        
        for (Contact c : [SELECT Email FROM Contact WHERE Email IN :emailMap.KeySet()]) {
            Lead c1 = emailMap.get(c.Email);            
            c1.Email.addError('Contact with this email address already exists');
        }         
    }  
    
    public static void populateAccountFields(List<Lead> leads, Map<Id, Lead> oldMap) {         
        
        Map<String, Lead> emailMap = new Map<String, Lead>();
        Set<Id> accountIds = new Set<Id>();
        
        for (Lead l : leads) {
            if (l.Convert_to_Enabled_Contact__c && l.Company_Referral_Account_Id__c != null) accountIds.add(l.Company_Referral_Account_Id__c );
        }
            
        if (accountIds.size() > 0) {
            Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Status_Enable_Disable__c, Email_Access__c, Portal_Access__c FROM Account WHERE Id IN: accountIds]);
            for (Lead l : leads) {
                l.Contact_Status__c = accountMap.get(l.Company_Referral_Account_Id__c).Status_Enable_Disable__c;
                l.Contact_Portal_Access__c = accountMap.get(l.Company_Referral_Account_Id__c).Portal_Access__c;
                l.Contact_Email_Access__c = accountMap.get(l.Company_Referral_Account_Id__c).Email_Access__c;
                if (l.Contact_Email_Access__c) l.Contact_Send_Preferences_Email__c = true;       
            }               
        }
    }  

    public static void convertLeads(List<Lead> leads){

        LeadStatus cLeadStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted = true LIMIT 1];
        List<Database.LeadConvert> massLeadConvert = new List<Database.LeadConvert>();
        
        Map<Id, Id> leadIdAccountIdMap = new Map<Id, Id>();
        for (Lead l : leads) {
            leadIdACcountIdMap.put(l.Id, l.Company_Referral_Account_Id__c);
        }
 
        for (Lead l : leads){

            if (!l.isConverted && l.Convert_to_Enabled_Contact__c && leadIdACcountIdMap.get(l.Id) != null) { 
                Database.LeadConvert LeadConvert = new Database.LeadConvert();
                LeadConvert.setLeadId(l.Id);
                LeadConvert.setConvertedStatus(cLeadStatus.MasterLabel);
                LeadConvert.setDoNotCreateOpportunity(true);
                LeadConvert.setAccountId(leadIdACcountIdMap.get(l.Id));
                massLeadConvert.add(LeadConvert);
            }
        }

        if(!massLeadConvert.isEmpty()){

            List<Database.LeadConvertResult> lcr = Database.convertLead(massLeadConvert);
            system.debug('### lcr = ' + lcr);
        }
    }  
    
    public static void setContactOwnerLookupfield(List<Lead> leads){
        
        List<Id> contactIds = new List<Id>();
        
        for (Lead l : leads) {
            if (l.isConverted && l.ConvertedContactId != null && l.Converted_Contact_Owner__c == null) {
                 
                contactIds.add(l.ConvertedContactId);
                }
        }
        
        if (contactIds.size() > 0) {
            
            Map<Id, Id> contactOwnerMap = new Map<Id, Id>(); 
            for (Contact c : [SELECT Id, OwnerId FROM Contact WHERE Id IN: contactIds]) {
                contactOwnerMap.put(c.Id, c.OwnerId);
            }                 
            
            for (Lead l : leads) {
                if (l.Converted_Contact_Owner__c != contactOwnerMap.get(l.ConvertedContactId)) 
                    l.Converted_Contact_Owner__c = contactOwnerMap.get(l.ConvertedContactId);
            }
        }
    }
    
     
}