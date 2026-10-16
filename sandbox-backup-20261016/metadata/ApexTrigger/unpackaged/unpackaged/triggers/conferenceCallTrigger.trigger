trigger conferenceCallTrigger on Conference_Call__c (before update, after update) {
    
    //system.debug('### conferenceCallTrigger');
    
    Portal_Setting__mdt settings = [SELECT EG_Event_trigger_active__c FROM Portal_Setting__mdt WHERE DeveloperName = 'Active_Settings'];
    
    if (Trigger.isBefore) {
        conferenceCallHandler.populateEGAttendeesDept(trigger.new);
    }
    if (Trigger.isAfter){
        conferenceCallHandler.createEvents(trigger.oldMap, trigger.new);
    }    
  
}