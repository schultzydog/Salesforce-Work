trigger EventTrigger on Event (before insert, before update, after insert, after update) {
    
    if ( ( Trigger.isAfter && Trigger.isInsert ) || ( Trigger.isAfter && Trigger.isUpdate ) ) {
        // egEventLogic is the live handler. blogic_Event is a parallel
        // implementation that is not wired up; do not swap them without a
        // dedicated testing pass.
        egEventLogic.createEGTimeEntry(Trigger.newMap);
    }
}