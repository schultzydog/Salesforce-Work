@isTest
Public class confCallStagingTriggerHandlerTest{

    static testMethod void myTest() {
    
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Department = 'Testing',
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@eurasiagroup.net');        
        insert u; 
             
        Account acct1 = new Account(Name='Eurasia Group', Status_Enable_Disable__c='Disabled', OwnerId = U.Id, Conference_Call_Access__c = TRUE);
        insert acct1;
        
        List<Contact> inserts = new List<Contact>();
        Contact TestContact1 = new Contact(AccountId = acct1.id,
                                           LastName = 'TestLastName1',
                                           Title = 'TestTitle',
                                           Status__c = 'Disabled',
                                           MailingCity = 'Testerville',
                                           Email = 'standarduser@eurasiagroup.net', OwnerId = U.Id);
        inserts.add(TestContact1);                               
        Contact TestContact2 = new Contact(AccountId = acct1.id,
                                           LastName = 'TestLastName2',
                                           Title = 'TestTitle',
                                           Status__c = 'Disabled',
                                           MailingCity = 'Testerville',
                                           Email = 'standarduser2@eurasiagroup.net', OwnerId = U.Id);                     
        insert inserts;
        
            
        Conference_Call__c cc = new Conference_Call__c(Name = 'test', Event_End_Time__c = datetime.now(), 
                                                        Event_Start_Time__c = datetime.now(), Location_Type__c = 'Virtual');
        insert cc;
           
        List<Conference_Call_Staging__c> ccsInserts = new List<Conference_Call_Staging__c>(); 
                
        Conference_Call_Staging__c leadTest = new Conference_Call_Staging__c(Conference_Call_new__c = cc.Id,
                                        Last_Name__c = 'leadtest', email__c = 'standarduser@eurasiagroup.net', Company__c = 'LeadTest');
        Conference_Call_Staging__c contactTest = new Conference_Call_Staging__c(Conference_Call_new__c = cc.Id,
                                        Last_Name__c = 'leadtest', email__c = 'leadtest@leadtest.com', Company__c = 'LeadTest');
        ccsInserts.add(leadTest);   
        ccsInserts.add(contactTest);  
                                        
        Test.startTest();     
        
        insert ccsInserts;
     
        Test.stopTest();
                                             
       
    }
}