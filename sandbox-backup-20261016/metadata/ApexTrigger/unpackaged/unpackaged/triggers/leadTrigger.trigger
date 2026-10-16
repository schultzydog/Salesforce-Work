trigger leadTrigger on Lead (before insert, before update, after update) {
     
     if (Trigger.isBefore) {
         blogic_Lead.preventLeadDupes(Trigger.new, Trigger.oldMap);
         blogic_Lead.populateAccountFields(Trigger.new, Trigger.oldMap);
         blogic_Lead.setContactOwnerLookupfield(Trigger.new);
     }
     
     if (Trigger.isAfter) {
         blogic_Lead.convertLeads(Trigger.new);
         
     }
}