@isTest
private class blogic_Lead_Tests {
    
    static testmethod void testDupePrevent(){
        
        Lead l1 = new Lead(LastName='Test Lname',Email='test@abc.com', Company='ABC');
        insert l1;    

        
        Lead l2 = new Lead(LastName='Test Lname',Email='test@abc.com', Company='ABC');
      
        try {   
            insert l2;
            //throw new MyException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
        
        } catch(Exception e){    
            Boolean expectedExceptionThrown = e.getMessage().contains('exists');
            System.AssertEquals(expectedExceptionThrown, true);
        }  
    } 
    
    static testmethod void testLeadConvert() {
        Account acct1 = new Account(Name='Test1', Status_Enable_Disable__c='Enabled');
        insert acct1;
    
        // create a Lead
        Lead lead = new Lead(LastName='TestDoe',FirstName='TestJane', 
                Company='TestUnknown',Status='Warm Prospect', Company_Referral_Account_Id__c = acct1.Id );
    
        insert lead;
        
        List<Id> leadIds = new List<Id>();
        leadIds.add(lead.Id);
    
        //now invoke the class and method - not do a convert which the invocable method is meant to do
        Test.startTest();   
            lead.Convert_to_Enabled_Contact__c = true;
            update lead;
        Test.stopTest();
    
        Lead converted = [SELECT Id, OwnerId, Status FROM Lead WHERE Id = :lead.Id];
        
        Contact newContact = [SELECT AccountId FROM Contact Limit 1];
        
        System.assertEquals(newContact.AccountId, acct1.Id);
        //System.assertEquals('### Qualified', converted.Status);
    }
}