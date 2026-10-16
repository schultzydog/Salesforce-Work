@isTest
public class egTimesheetMetrics_Ctlr_Tests {
    
    static testmethod void testMetricsController() {

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser12323421321@testorg.com');
        insert u;
        
        EG_Project__c proj = new EG_Project__c(Name='test project');
        insert proj;
        
        EG_Project_Task__c task1 = new EG_Project_Task__c(Name='test task 1', EG_Project__c=proj.Id);
        insert task1;
        
        EG_Project_Task__c task2 = new EG_Project_Task__c(Name='test task 2', EG_Project__c=proj.Id);
        insert task2;

        System.runAs(u) {
            EG_Time_Card__c card = new EG_Time_Card__c();
            card.OwnerId = u.Id;
            card.Start_Date__c = Date.today().toStartOfWeek();
            card.End_Date__c = Date.today().toStartOfWeek().addDays(6);
            card.Name = 'test';
            insert card;
            
            EG_Time_Entry__c entry1 = new EG_Time_Entry__c();
            entry1.EG_Time_Card__c = card.Id;
            entry1.Date__c = Date.today();
            entry1.EG_Project__c = proj.Id;
            entry1.EG_Project_Task__c = task1.Id;
            entry1.Hours_Worked__c = 1;
            insert entry1;
            
            EG_Time_Entry__c entry2 = new EG_Time_Entry__c();
            entry2.EG_Time_Card__c = card.Id;
            entry2.Date__c = Date.today();
            entry2.EG_Project__c = proj.Id;
            entry2.EG_Project_Task__c = task2.Id;
            entry2.Hours_Worked__c = 2;
            insert entry2;
    

            egTimesheetMetrics_Ctlr.MetricsWrapper wrapper = egTimesheetMetrics_Ctlr.queryTimecards(u.Id);
            System.assertEquals(String.valueOf(Date.today().year()), wrapper.complianceYear);
            System.assertEquals(1, wrapper.rows.size());
            egTimesheetMetrics_Ctlr.queryTimecardsByDate(Date.today());
        
        }

    }

}