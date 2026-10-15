/**
 * @description       : Trigger on Contact
**/
trigger ContactTrigger on Contact (before insert, after insert, before update, after update, before delete, after delete) {
    Portal_Setting__mdt settings = [SELECT Contact_Trigger_Active__c FROM Portal_Setting__mdt WHERE DeveloperName = 'Active_Settings'];

    
    if (Trigger.isUpdate) {
        if (Trigger.isAfter){   
            if (settings.Contact_Trigger_Active__c && trigger.new[0].Include_in_Analyst_picklist_value_set__c != trigger.old[0].Include_in_Analyst_picklist_value_set__c) 
                blogic_Contact.toolingcallouts();          
        } 
        
        if (Trigger.isBefore){
            //if (settings.Contact_Trigger_Active__c) blogic_Contact.preventContactDupes(Trigger.new, Trigger.oldMap);                 
            blogic_Contact.createNewExternalId(Trigger.new);
        }
    }
    if (Trigger.isInsert) {
        //if (settings.Contact_Trigger_Active__c) PortalAPIEntitlements.sendContactProfiles(null, Trigger.newMap);
        if (Trigger.isBefore) {
            blogic_Contact.createNewExternalId(Trigger.new);        
        }
        
        if (Trigger.isAfter) {
            if (settings.Contact_Trigger_Active__c && trigger.new[0].Include_in_Analyst_picklist_value_set__c) blogic_Contact.toolingcallouts();
        }    
    } 
}