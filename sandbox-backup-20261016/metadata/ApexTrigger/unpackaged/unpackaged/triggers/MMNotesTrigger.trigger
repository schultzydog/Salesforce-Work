trigger MMNotesTrigger on Morning_Meeting_Note__c (before insert) {
   
    Portal_Setting__mdt settings = [SELECT Morning_Meeting_Note_Trigger_Active__c FROM Portal_Setting__mdt WHERE DeveloperName = 'Active_Settings'];
    system.debug('### in trigger' );
    if (settings.Morning_Meeting_Note_Trigger_Active__c) {
        //if (trigger.isAfter ) {
            if (!Trigger.New[0].Email_Sent__c) blogic_MMNotes.doLogic(Trigger.New);
       // } 
    }
}