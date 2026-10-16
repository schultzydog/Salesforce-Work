public class opportunityAmountTriggerHandler {
    public static void updateAccountDescription (List<Opportunity> opp){
        Map<Id, Id> accountIdToOpportunityId = new Map<Id, Id>();
		for (Opportunity op : opp){
			if (op.amount > 100000 && op.accountId != NULL){
                	accountIdToOpportunityId.put(op.AccountId, op.Id);
        	}
    	}
        if(accountIdToOpportunityId.isEmpty()){
            return;
        }
        List<Account> accountsToUpdate = [SELECT Id FROM Account WHERE Id IN :accountIdtoOpportunityID.keySet()];
        for (Account acc : accountsToUpdate){
            acc.description = String.valueOf(accountIdToOpportunityId.get(acc.Id));
        }
        update accountsToUpdate;
	}
}