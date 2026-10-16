@isTest
Public class conferenceCallHandlerTest {
  
    static testMethod void myTest() {
    
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u1 = new User(Alias = 'standt', Email='standarduser1abcde@eurasiagroup.net', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Department__c = 'Information Technology',
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1@eurasiagroup.net');        
        insert u1; 
        
        User u2 = new User(Alias = 'standt', Email='standarduser1abcdef@eurasiagroup.net', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Department__c = 'Information Technology',
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser2@eurasiagroup.net');        
        insert u2; 
        
        User u3 = new User(Alias = 'standt', Email='standarduser1abcdefg@eurasiagroup.net', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, Department__c = 'Information Technology',
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser3@eurasiagroup.net');        
        insert u3; 
             
        Account acct1 = new Account(Name='Eurasia Group', Status_Enable_Disable__c='Disabled', OwnerId = u1.Id);
        insert acct1;
        
        Opportunity opp1 = new Opportunity(Name='Eurasia Group', AccountId = acct1.Id, CloseDate = System.today(), StageName = 'Not Started');
        insert opp1;
        
        List<Contact> inserts = new List<Contact>();
        
 		List<Contact> testContacts = [SELECT Email FROM Contact];
        system.debug('### testContacts = ' + testContacts);
        
        //if (testContacts.size() < 1) {
            Contact TestContact1 = new Contact(AccountId = acct1.id,
                                               LastName = 'TestLastName1',
                                               Title = 'TestTitle',
                                               Status__c = 'Disabled',
                                               MailingCity = 'Testerville',
                                               Email = 'standarduser1abcde@eurasiagroup.net');
            inserts.add(TestContact1);                               
            Contact TestContact2 = new Contact(AccountId = acct1.id,
                                               LastName = 'TestLastName2',
                                               Title = 'TestTitle',
                                               Status__c = 'Disabled',
                                               MailingCity = 'Testerville',
                                               Email = 'standarduser1abcdef@eurasiagroup.net');
            inserts.add(TestContact2);                                           
            Contact TestContact3 = new Contact(AccountId = acct1.id,
                                               LastName = 'TestLastName3',
                                               Title = 'TestTitle',
                                               Status__c = 'Disabled',
                                               MailingCity = 'Testerville',
                                               Email = 'standarduser1abcdefg@eurasiagroup.net');                                                                                      
            inserts.add(TestContact3);    
            insert inserts;
       // }    
        
        
        Department__c itDept = new Department__c(Name = 'Information Technology');
        insert itDept;
        
        Lead tester = new Lead(LastName = 'test', Email = 'test@test.com3873', Company = 'test');
        insert tester;
     
        Conference_Call__c cc = new Conference_Call__c(Name = 'test', Event_End_Time__c = datetime.now(), Event_Start_Time__c = datetime.now());
        insert cc;
        
        List<EG_Event_Registrant__c> cccinserts = new List<EG_Event_Registrant__c>();
        EG_Event_Registrant__c ccc1 = new EG_Event_Registrant__c (Contact__c = TestContact1.Id, EG_Event__c = cc.Id, Attended__c = TRUE );
        EG_Event_Registrant__c ccc2 = new EG_Event_Registrant__c (Contact__c = TestContact2.Id, EG_Event__c = cc.Id, Attended__c = TRUE );
        EG_Event_Registrant__c ccc3 = new EG_Event_Registrant__c (Contact__c = TestContact3.Id, EG_Event__c = cc.Id, Attended__c = TRUE );
        cccinserts.add(ccc1);
        cccinserts.add(ccc2);
        cccinserts.add(ccc3);
        insert cccinserts;
        
        List<Conference_Call_Speaker__c> speakerInserts = new List<Conference_Call_Speaker__c>();
        Conference_Call_Speaker__c speaker1 = new Conference_Call_Speaker__c (Speaker__c = TestContact1.Id, Conference_Call__c= cc.Id );
        Conference_Call_Speaker__c speaker2 = new Conference_Call_Speaker__c (Speaker__c = TestContact2.Id, Conference_Call__c= cc.Id );
        Conference_Call_Speaker__c speaker3 = new Conference_Call_Speaker__c (Speaker__c = TestContact3.Id, Conference_Call__c= cc.Id );
        insert speaker1;
        insert speaker2;
        insert speaker3;    
        
        EG_Event_Registrant__c ccl1 = new EG_Event_Registrant__c (Lead__c = tester.Id, EG_Event__c = cc.Id, Attended__c = TRUE );
        insert ccl1;
        
        
        
        Test.startTest();     
        
        cc.Create_Activity_History__c = TRUE;
        update cc;
 
        Test.stopTest();
        
        Conference_Call__c ccpost = [SELECT Speaker_Departments__c FROM Conference_Call__c WHERE Id =: cc.Id LIMIT 1];
        //system.debug('### ccpost speaker depts = ' + ccpost.Speaker_Departments__c );
        
        List<Event> eventsPostTest = [SELECT Id FROM Event WHERE Conference_Call__c = :cc.Id AND (Contact_Lead__c = 'Lead' OR Contact_Lead__c = 'Contact')];
        system.assert(eventsPostTest.size() == 2);    
        List<EventRelation> erPostTest = [SELECT Id, EventId, Relation.Name FROM EventRelation 
                                            WHERE EventId IN :eventsPostTest ];
        system.assert(erPostTest.size() == 5);        
        
        List<Conference_Call_Department__c> ccDepts = [SELECT Id FROM Conference_Call_Department__c];
        system.assert(ccDepts.size() > 0);                                     
       
    }
}