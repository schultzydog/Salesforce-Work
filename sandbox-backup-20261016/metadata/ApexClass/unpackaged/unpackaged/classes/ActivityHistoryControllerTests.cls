@isTest
public class ActivityHistoryControllerTests {
    
    static testmethod void testActivityHistory(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='activityhistorytest@testmethod.com');
        insert u;
        
        Account a = new Account();
        a.Name = 'test';
        insert a;
        
        Task t = new Task();
        t.OwnerId = u.Id;
        t.ActivityDate = Date.today();
        t.Subject = 'test';
        t.WhatId = a.Id;
        insert t;
        
        Event e = new Event();
        e.OwnerId = u.Id;
        e.ActivityDate = Date.today();
        e.Subject = 'test';
        e.WhatId = a.Id;
        e.StartDateTime=system.today();
        e.EndDateTime=system.today()+5;
        insert e;
        
        System.Assert( ActivityHistoryController.getActivityHistoryApex(a.Id) != null );
        
    }
    
}