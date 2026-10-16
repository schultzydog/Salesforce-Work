@isTest
global class blogic_Contact_Tests {
    
    static testmethod void testChangeAccount(){
    
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse()); 
        
        Account a1 = new Account(Name='Test Account 1 ', Conference_Call_Access__c = TRUE);
        insert a1;
        Account a2 = new Account(Name='Test Account 2', Conference_Call_Access__c = TRUE);
        insert a2;
        Contact c = new Contact(LastName='Test Lname',AccountId=a1.Id,Email='test@abc.com',Include_in_Analyst_picklist_value_set__c = true, eg_update_name__c ='test' );
        c.Status__c = 'Enabled';
        c.Date_First_Research_Sent__c = Date.today();
        c.Subscribed_to_Aggregator_Services__c  = true;
        c.Selected_Aggregators__c = 'Bloomberg';
        c.Deliver_Full_Content_Emails__c = TRUE;
        
        insert c;
        Library__c l1 = new Library__c(Name = 'Test Library');
        insert l1;
        Library__c l2 = new Library__c(Name = 'Test Library');
        insert l2;
        Account_Preferences__c aPref1 = new Account_Preferences__c(Account__c = a1.Id, Library__c = l1.Id);
        insert aPref1;
        Account_Preferences__c aPref2 = new Account_Preferences__c(Account__c = a1.Id, Library__c = l2.Id);
        insert aPref2;
        Account_Preferences__c aPref3 = new Account_Preferences__c(Account__c = a2.Id, Library__c = l1.Id);
        insert aPref3;
        Contact_Preferences__c cPref1 = new Contact_Preferences__c(Account_Preferences__c = aPref1.Id, Contact__c = c.Id);
        insert cPref1;
        Contact_Preferences__c cPref2 = new Contact_Preferences__c(Account_Preferences__c = aPref2.Id, Contact__c = c.Id);
        insert cPref2;
        
        c.AccountId = a2.Id;
        c.Status__c = 'Enabled';
        //c.Research_Status__c = 'is Receiving Research';
        c.Date_First_Research_Sent__c = Date.today();
        c.Subscribed_to_Aggregator_Services__c = false;
        c.Selected_Aggregators__c = null;
        c.Include_in_Analyst_picklist_value_set__c = false;
        
        Test.startTest();
        update c;

        delete c;
        Test.stopTest();
    }
    
    static testmethod void testDupeContact(){
    
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse()); 
        
        Account a1 = new Account(Name='Test Account 1 ', Conference_Call_Access__c = TRUE);
        insert a1;
        Account a2 = new Account(Name='Test Account 2', Conference_Call_Access__c = TRUE);
        insert a2;
        Contact c = new Contact(LastName='Test Lname',AccountId=a1.Id,Email='test@abc.com',Include_in_Analyst_picklist_value_set__c = true, eg_update_name__c ='test' );
        c.Status__c = 'Enabled';
        c.Date_First_Research_Sent__c = Date.today();
        c.Subscribed_to_Aggregator_Services__c  = true;
        c.Selected_Aggregators__c = 'Bloomberg';
        c.Deliver_Full_Content_Emails__c = TRUE;
        
        insert c;
        
        Contact c2 = new Contact(LastName='Test Lname',AccountId=a1.Id,Email='test@abc.com',Include_in_Analyst_picklist_value_set__c = true, eg_update_name__c ='test' );
        c2.Status__c = 'Enabled';
        c2.Date_First_Research_Sent__c = Date.today();
        c2.Subscribed_to_Aggregator_Services__c  = true;
        c2.Selected_Aggregators__c = 'Bloomberg';
        c2.Deliver_Full_Content_Emails__c = TRUE;
        
        Test.startTest();
        try {
            insert c2;
            System.assert(false, 'Should have thrown a duplicate exception!');
        } catch(DmlException e) {
            System.debug('ERROR: ' + e.getMessage());
        }
        Test.stopTest();
                
           
        /*
        Library__c l1 = new Library__c(Name = 'Test Library');
        insert l1;
        Library__c l2 = new Library__c(Name = 'Test Library');
        insert l2;
        Account_Preferences__c aPref1 = new Account_Preferences__c(Account__c = a1.Id, Library__c = l1.Id);
        insert aPref1;
        Account_Preferences__c aPref2 = new Account_Preferences__c(Account__c = a1.Id, Library__c = l2.Id);
        insert aPref2;
        Account_Preferences__c aPref3 = new Account_Preferences__c(Account__c = a2.Id, Library__c = l1.Id);
        insert aPref3;
        Contact_Preferences__c cPref1 = new Contact_Preferences__c(Account_Preferences__c = aPref1.Id, Contact__c = c.Id);
        insert cPref1;
        Contact_Preferences__c cPref2 = new Contact_Preferences__c(Account_Preferences__c = aPref2.Id, Contact__c = c.Id);
        insert cPref2;
        
        c.AccountId = a2.Id;
        c.Status__c = 'Enabled';
        //c.Research_Status__c = 'is Receiving Research';
        c.Date_First_Research_Sent__c = Date.today();
        c.Subscribed_to_Aggregator_Services__c = false;
        c.Selected_Aggregators__c = null;
        c.Include_in_Analyst_picklist_value_set__c = false;
        update c;

        delete c;
        */
    }
    
    global class MockHttpResponse implements HttpCalloutMock {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            //System.assertEquals('https://eurasiagroup--bolterra.sandbox.my.salesforce.com/services/data/v60.0/tooling/sobjects/GlobalValueSet/0Nt3A000000L3mi?_HttpMethod=PATCH', req.getEndpoint());
            System.assertEquals('PATCH', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
}