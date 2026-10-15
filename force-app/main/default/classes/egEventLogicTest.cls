@isTest
public class egEventLogicTest {
    
    static testmethod void testGenerateTimeEntry() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u1 = new User(Alias = 'standt', Email='test1@test.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='1534535235@testorg.com');
        insert u1;
        User u2 = new User(Alias = 'standt', Email='test2@test.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='134532645363145@testorg.com');
        insert u2;
        
        EG_Project__c proj = new EG_Project__c(Name='test project');
        insert proj;
        
        EG_Project_Task__c task1 = new EG_Project_Task__c(Name='test task 1', EG_Project__c=proj.Id);
        insert task1;
        
        EG_Time_Card__c card1 = new EG_Time_Card__c();
        card1.OwnerId = u1.Id;
        card1.Start_Date__c = Date.today().toStartOfWeek();
        card1.End_Date__c = Date.today().toStartOfWeek().addDays(6);
        card1.Name = 'test';
        insert card1;
        
        EG_Time_Card__c card2 = new EG_Time_Card__c();
        card2.OwnerId = u2.Id;
        card2.Start_Date__c = Date.today().toStartOfWeek();
        card2.End_Date__c = Date.today().toStartOfWeek().addDays(6);
        card2.Name = 'test';
        insert card2;
        
        Account a = new Account(Name='test', OwnerId=u1.Id);
        insert a;
        
        Contact c = new Contact(AccountId=a.Id, LastName='test', Email='test2@test.com', OwnerId=u1.Id);
        insert c;
        
        
        Date d = card1.Start_Date__c.addDays(1);
        Event e = new Event();
        e.WhatId = proj.Id;
        e.OwnerId = u1.Id;
        DateTime startTime = DateTime.newInstance(d.year(), d.month(), d.day(), 12, 0, 0);
        e.StartDateTime = startTime;
        e.DurationInMinutes = 60;
        insert e;
        
        EventRelation er = new EventRelation();
        er.EventId = e.Id;
        er.RelationId = c.Id;
        er.isParent = false;
        insert er;
        
        update e;
 
        Event newEventSeries = new Event(
            Subject = 'Daily Team Sync',
            WhatId = proj.Id,
            StartDateTime = DateTime.newInstance(2032, d.month(), d.day(), 12, 0, 0),
            DurationInMinutes = 60,
            // Use an RRULE (Recurrence Rule) to define the pattern
            // This rule creates a series that repeats daily, 5 times in total
            Recurrence2PatternText = 'RRULE:FREQ=DAILY;INTERVAL=1;COUNT=5' 
        );
        
        insert newEventSeries;
                    
        List<EG_Time_Entry__c> entries = [SELECT Id, Time_Entry_Source__c FROM EG_Time_Entry__c];
        System.Assert(entries.size() >= 1);
        for (EG_Time_Entry__c entry : entries) {
            System.assertEquals('Automation', entry.Time_Entry_Source__c);
        }

        
    }
    
}