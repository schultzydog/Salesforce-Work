trigger DeliverableTrigger on Deliverable__c (before insert, before update) {
    
    system.debug('### in trigger' );
    blogic_Deliverables.doLogic(Trigger.New);
    
}