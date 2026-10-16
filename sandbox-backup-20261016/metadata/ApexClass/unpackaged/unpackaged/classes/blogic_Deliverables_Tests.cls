@isTest
private class blogic_Deliverables_Tests {
    
    static testmethod void test1() {
    
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

        User manager = new User(Alias = 'standt', Email='standardmanager@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Department__c = 'Finance',
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser123322@testorg.com');
        insert manager;  
        
        User u = new User(Alias = 'standt', Email='lieber@eurasiagroup.net', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, ManagerId = manager.Id,Department__c = 'Finance',
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser123321@testorg.com');
        insert u;
        
  
        Account acct1 = new Account(Name='Test1', Status_Enable_Disable__c='Disabled', Conference_Call_Access__c = TRUE, OwnerId = u.Id);
        insert acct1;
        
        Opportunity opp1 = new Opportunity(Name='test opp1',
                                            AccountId = acct1.Id,
                                            StageName='0% - Prospect',
                                            OwnerId = u.Id,
                                            Amount = 2500, 
                                            CloseDate=system.today(), 
                                            RevenueType__c = 'Recurring',
                                            Business_Line__c = 'GZERO',
                                            Contract_Start_Date__c = System.Today().addDays(-90),
                                            Contract_End_Date__c = System.Today().addDays(+90),
                                           PO_Required__c = 'No', 
                                           Multi_year_Contract__c = 'No'); 
        insert opp1;


        Deliverable__c deliverable = new Deliverable__c();
        deliverable.Opportunity__c = opp1.Id;
        deliverable.Name = 'Test';
        deliverable.Analysts_Needed__c = 'lieber@eurasiagroup.net';
         

           
        Test.startTest();   
            insert deliverable;
        Test.stopTest();
        
    }
    
}