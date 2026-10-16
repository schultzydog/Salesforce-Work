trigger opportunityTrigger on Opportunity (before update, after update) {

    //BEFORE UPDATE
    //if(Trigger.isBefore && Trigger.isUpdate){    
        //opportunityHandler.populateProductsField(trigger.new);
    //}
    
    //AFTER UPDATE
    if(Trigger.isAfter && Trigger.isUpdate){    
        //opportunityHandler.populateProductsFieldonAccount(trigger.new);
        opportunityHandler.syncProjectsAndTasksWithOpportunitiesAndProducts(Trigger.newMap); //Added for EG Timesheets - Bryan 5/7/2022
    }    
    
}