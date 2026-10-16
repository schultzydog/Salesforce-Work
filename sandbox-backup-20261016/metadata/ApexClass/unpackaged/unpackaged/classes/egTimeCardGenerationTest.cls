@isTest
public class egTimeCardGenerationTest {
    
    static testmethod void testCreateTimeCard() {
        
        User u = new User();
        u.Alias = 'name';
        u.Email = 'fakeuser@testuser.com';
        u.EmailEncodingKey = 'UTF-8';
        u.LastName = 'Admin';
        u.FirstName = 't';
        u.languageLocaleKey = 'en_US';
        u.LocalesIdKey = 'en_US';
        u.ProfileId = [SELECT ID FROM Profile WHERE Name = 'System Administrator'].Id;
        u.TimezonesIdKey = 'America/Chicago';
        u.Username = 'test111222333444445555667788899@fakeemail.com';
        u.Title = 'None';
        u.isActive = true;
        u.Timesheet_Required__c  = true;
        insert u;    
        
        Test.startTest();
        Database.executeBatch( new egTimeCardGenerationBatch() );
        
    }
    
    static testmethod void testSchedule(){
        
        Test.StartTest();
		egTimeCardGenerationSched sh1 = new egTimeCardGenerationSched();
		String sch = '0 0 23 * * ?';
        system.schedule('Test', sch, sh1);
        Test.stopTest();
    
    }
    
}