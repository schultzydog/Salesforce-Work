trigger opportunityAmountTrigger on Opportunity (after insert, after update) {
    	opportunityAmountTriggerHandler.updateAccountDescription(trigger.new);
}