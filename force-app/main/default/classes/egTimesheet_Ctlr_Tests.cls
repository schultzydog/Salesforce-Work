@isTest
private class egTimesheet_Ctlr_Tests {
    
    static testmethod void testGetTimesheet(){ 
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser123321@testorg.com');
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
    
            egTimesheet_Ctlr.TimesheetWrapper wrapper = egTimesheet_Ctlr.getTimesheetForDateApex(null, null, null);
            egTimesheet_Ctlr.TimesheetWrapper wrapper2 = egTimesheet_Ctlr.getTimesheetForDateApex(Date.today().addDays(100), null, null);

            egTimesheet_Ctlr.saveTimesheetApex(wrapper.timeCardId, null, wrapper.startDate, wrapper.rows, new List<String>{null,null,null,null,'WFH'});
            
        }
        
    }

    /**
     * Prefill copies last week's project/task pairs onto an empty week. A pair
     * is dropped when either the project or the task is Inactive.
     */
    static testmethod void prefillDropsInactiveProjectsAndTasks(){

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'prefil', Email='prefill@testorg.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='prefillinactive@testorg.com');
        insert u;

        EG_Project__c activeProject = new EG_Project__c(Name='active project', Status__c='Active');
        EG_Project__c inactiveProject = new EG_Project__c(Name='inactive project', Status__c='Inactive');
        insert new List<EG_Project__c>{ activeProject, inactiveProject };

        EG_Project_Task__c activeTask = new EG_Project_Task__c(
            Name='active task', EG_Project__c=activeProject.Id, Status__c='Active');
        EG_Project_Task__c inactiveTask = new EG_Project_Task__c(
            Name='inactive task', EG_Project__c=activeProject.Id, Status__c='Inactive');
        EG_Project_Task__c taskOnInactiveProject = new EG_Project_Task__c(
            Name='task on inactive project', EG_Project__c=inactiveProject.Id, Status__c='Active');
        insert new List<EG_Project_Task__c>{ activeTask, inactiveTask, taskOnInactiveProject };

        System.runAs(u) {

            Date selectedDate = Date.today();
            Integer dayOfWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(selectedDate), 7);
            Date lastWeekStart = selectedDate.addDays(-dayOfWeek).addDays(-7);

            EG_Time_Card__c lastWeek = new EG_Time_Card__c(
                OwnerId = u.Id,
                Start_Date__c = lastWeekStart,
                End_Date__c = lastWeekStart.addDays(6),
                Name = 'last week'
            );
            insert lastWeek;

            List<EG_Time_Entry__c> lastWeekEntries = new List<EG_Time_Entry__c>{
                new EG_Time_Entry__c(EG_Time_Card__c=lastWeek.Id, Date__c=lastWeekStart, Hours_Worked__c=1,
                    EG_Project__c=activeProject.Id, EG_Project_Task__c=activeTask.Id),
                new EG_Time_Entry__c(EG_Time_Card__c=lastWeek.Id, Date__c=lastWeekStart, Hours_Worked__c=1,
                    EG_Project__c=activeProject.Id, EG_Project_Task__c=inactiveTask.Id),
                new EG_Time_Entry__c(EG_Time_Card__c=lastWeek.Id, Date__c=lastWeekStart, Hours_Worked__c=1,
                    EG_Project__c=inactiveProject.Id, EG_Project_Task__c=taskOnInactiveProject.Id)
            };
            insert lastWeekEntries;

            egTimesheet_Ctlr.TimesheetWrapper wrapper =
                egTimesheet_Ctlr.getTimesheetForDateApex(selectedDate, u.Id, true);

            Set<String> prefilled = new Set<String>();
            for (egTimesheet_Ctlr.TimesheetRow row : wrapper.rows) {
                if (row.projectId == null) continue;
                prefilled.add(String.valueOf(row.projectId) + ':' + String.valueOf(row.taskId));
            }

            System.assert(prefilled.contains(activeProject.Id + ':' + activeTask.Id),
                'An active project and task from last week should be prefilled.');
            System.assert(!prefilled.contains(activeProject.Id + ':' + inactiveTask.Id),
                'An inactive task should not be prefilled.');
            System.assert(!prefilled.contains(inactiveProject.Id + ':' + taskOnInactiveProject.Id),
                'An inactive project should not be prefilled.');
            System.assertEquals(1, prefilled.size(),
                'Only the active project and task pair should be copied forward.');
        }
    }

}
