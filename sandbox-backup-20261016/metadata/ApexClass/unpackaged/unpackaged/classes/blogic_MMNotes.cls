/**
 * @description       : Trigger handler for Morning Meeting Notes
                      : Trigger handler is not bulkified  
**/
public class blogic_MMNotes {

    public static void doLogic(List<Morning_Meeting_Note__c> mmNotes){
        
        //Morning_Meeting_Note__c mmNote = mmNotes[0];
        List<String> contributorEmails = new List<String>();
        List<String> practiceHeadEmails = new List<String>();
        Set<String> emailsForCCSendingSet = new Set<String>();
        List<String> emailsForCCSendingList = new List<String>();
        List<string> toAddress = new List<string>();
        List<Messaging.SingleEmailMessage> msgList=new List<Messaging.SingleEmailMessage>();
        
        //Get Contributors list
        for (Morning_Meeting_Note__c mmNote : mmNotes) {
            
            if (mmNote.Submitted_By_Email__c != null) {
            system.debug('### Submitted_By_Email__c= ' + mmNote.Submitted_By_Email__c );
            emailsForCCSendingSet.add(mmNote.Submitted_By_Email__c);
            
            }
            if (mmNote.egContributors__c != null) contributorEmails = mmNote.egContributors__c.split(';');
            if (mmNote.Distribution_Lists__c != null) practiceHeadEmails = mmNote.Distribution_Lists__c.split(';');
            toAddress.add(mmNote.Morning_Meeting_Email__c);
            system.debug('### contributorEmails = ' + contributorEmails );
            system.debug('### practiceHeadEmails = ' + practiceHeadEmails );
            
        }   
        
        if (contributorEmails.size() > 0) {
            for (String ce: contributorEmails) {
                emailsForCCSendingSet.add(ce);
            }
        }
        
        if (practiceHeadEmails.size() > 0) {
            for (String phe: practiceHeadEmails) {
                emailsForCCSendingSet.add(phe);
                emailsForCCSendingSet.add('EditorialCommittee@eurasiagroup.net');
                emailsForCCSendingSet.add('morningmeeting@eurasiagroup.net');
            }
        }
         
        emailsForCCSendingList.addAll(emailsForCCSendingSet); 
                  
        if ( emailsForCCSendingSet.size() > 0) {
            mmNotes[0].Email_List__c = String.join(emailsForCCSendingList, ',');
        }
        
 /**         
        EmailTemplate template = [Select Id FROM EmailTemplate WHERE DeveloperName = 'Morning_Meeting_Note_Submission' LIMIT 1]; 
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'communications@eurasiagroup.net' LIMIT 1];
        
        if (emailsForCCSendingList.size() > 0) {
            //String mmLink='<a href= "'+System.Url.getSalesforceBaseUrl().toExternalForm()+'/'+mmNotes[0].Id+'">'+System.Url.getSalesforceBaseUrl().toExternalForm()+'/'+mmNotes[0].Id+'</a>';
            //URL.getOrgDomainURL().toExternalForm() + '/' + doc.id;
            String mmLink = URL.getOrgDomainURL().toExternalForm() + '/' + mmNotes[0].Id;          
            
            system.debug('### mmLink = ' + mmLink);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
            //mail.setTargetObjectId(mmNotes[0].Id);
            mail.setToAddresses(toAddress);
            mail.setccAddresses(emailsForCCSendingList);
            mail.setHTMLBody('Topic: '+ mmNotes[0].Topic__c +  
                '<br/><br/>Title: '+ mmNotes[0].Proposed_Title__c +  
                '<br/><br/>Arguments: '+ mmNotes[0].Argument__c+  
                '<br/><br/>Lead Author: '+ mmNotes[0].egLead_Author__c +  
                '<br/><br/>Contributors: '+ mmNotes[0].egContributors__c +  
                '<br/><br/>Distribution: '+ mmNotes[0].Distribution_Lists__c+  
                '<br/><br/>Link to record in SF: '+ mmLink);
                
                

            //mail.setTemplateId(template.Id);
            //mail.setSaveAsActivity(true);
            mail.setUseSignature(false);
            
            msgList.add(mail);
            //if(msgList.size()>0) Messaging.sendEmail(msgList);                
        }
**/        
    }
}