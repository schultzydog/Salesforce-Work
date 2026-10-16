@istest
public class opportunityAmountTriggerTest {
	@istest
    static void opportunityOver100000(){
		Account acc = new Account(Name = 'Test Account');
        INSERT acc; 
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Closed', Closedate = Date.today(), Amount = 100001, accountId = acc.id);
        INSERT opp;
        Account updatedAccount = [
    		SELECT Id, Description
    		FROM Account
    		WHERE Id = :acc.Id
		];
        Assert.areEqual(String.valueOf(opp.Id), updatedAccount.Description);
    }
    @istest
    static void opportunityUnder100000(){
		Account acc = new Account(Name = 'Test Account');
        INSERT acc; 
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Closed', Closedate = Date.today(), Amount = 99999, accountId = acc.id);
        INSERT opp;
        Account updatedAccount = [
    		SELECT Id, Description
    		FROM Account
    		WHERE Id = :acc.Id
		];
        Assert.isNull(updatedAccount.Description);
    }
    @istest
      static void opportunityover100000afterUpdate(){
		Account acc = new Account(Name = 'Test Account');
        INSERT acc; 
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Closed', Closedate = Date.today(), Amount = 99999, accountId = acc.id);
        INSERT opp;
        Account updatedAccount = [
    		SELECT Id, Description
    		FROM Account
    		WHERE Id = :acc.Id
		];
        opp.Amount = 100001;
        update opp;
            Account updatedAccount2 = [
    		SELECT Id, Description
    		FROM Account
    		WHERE Id = :acc.Id
		];
        Assert.areEqual(String.valueOf(opp.Id), updatedAccount2.Description);
    }
}