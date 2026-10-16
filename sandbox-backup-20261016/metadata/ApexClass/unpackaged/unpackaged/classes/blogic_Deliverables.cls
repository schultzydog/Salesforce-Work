/**
 * @description       : Trigger handler for Deliverables
                      : Trigger handler is not bulkified  
**/
public class blogic_Deliverables {

    public static void doLogic(List<Deliverable__c> deliverables){
        
        List<String> analystEmails = new List<String>();
        List<String> managerEmails = new List<String>();
        Set<String> managerEmailsSet = new Set<String>();
        
        for (Deliverable__c deliverable: deliverables) {
        
            if (deliverable.Analysts_Needed__c != null) {
                deliverable.Notify_Analysts_Email_List__c = deliverable.Analysts_Needed__c.replace(';', ',');
                analystEmails = deliverable.Notify_Analysts_Email_List__c.split(',');
                //system.debug('### analystEmails  = ' + analystEmails );   
 
                for (User manager : [SELECT Manager.Email FROM User WHERE Email IN: analystEmails ]) {
                    if (manager.manager.email != null) managerEmailsSet.add(manager.manager.email);
                    //system.debug('### manager.email = ' + manager.manager.email  );
                }
                
                deliverable.Notify_Managers_Email_List__c = null;
                
                if (managerEmailsSet.size() > 0) {
                    for (String managerEmail : managerEmailsSet ){
                        deliverable.Notify_Managers_Email_List__c += managerEmail + ',';                   
                    }      
                    deliverable.Notify_Managers_Email_List__c = deliverable.Notify_Managers_Email_List__c.removeStartIgnoreCase('null');     
                }
                
            }        
        }       
    }
}