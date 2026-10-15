public without sharing class egTimesheet_Ctlr {
    
    @AuraEnabled
    public Static TimesheetWrapper getTimesheetForDateApex(Date selectedDate, Id timeCardUserId, Boolean prefill){
        System.debug('Entering getTimesheetForDateApex');

        if(prefill==null) prefill = false; //prefill project and tasks names from last week
        System.debug('prefill:' + prefill);

        TimesheetWrapper wrapper = new TimesheetWrapper(); //return object

        //Get running user...
        User runningUser = [SELECT Id, Name, Department__c, FirstName, LastName, Remote__c,
                            (SELECT Id FROM PermissionSetAssignments
                             WHERE PermissionSet.Name = 'Timesheet_Administrators' AND AssigneeId = :UserInfo.getUserId()) 
                            FROM User WHERE Id = :UserInfo.getUserId()];
        wrapper.runningUser = runningUser;
        List<Department__c> depts = [SELECT Id, Name FROM Department__c WHERE Name =: runningUser.Department__c];
        System.debug('runningUser:' + runningUser);

        //Get timecard user...
        if(timeCardUserId==null) timeCardUserId = runningUser.Id;
        User timeCardUser = [SELECT Id, Name, FirstName, LastName, Remote__c FROM User WHERE Id = :timeCardUserId];
        wrapper.timeCardUser = timeCardUser;
        System.debug('timeCardUser:' + timeCardUser);

        //Get timecard selected date...
        if(selectedDate==null) selectedDate = Date.today(); //default selected date to today
        System.debug('selectedDate:' + selectedDate);
        //System.debug('selectedDate:' + selectedDate);

        //HOTFIX 20250112: For users with positive timezone offsets (Germany or China for example), when navigating to past timesheets,
        // once the Daylight Savings Time is crossed, then we get wrong dates.
        // To detect this, we look for difference beteen formatGmt and format local.
        // To fix this, we add one day to the selected date when there is a difference between formats (indicating a positive timezone offset)
        System.debug('selectedDate asGMT: ' + ((DateTime)selectedDate).formatGmt('yyyy-MM-dd'));
        System.debug('selectedDate Local: ' + ((DateTime)selectedDate).format('yyyy-MM-dd'));
        /*
        if(Date.valueOf(((DateTime)selectedDate).formatGmt('yyyy-MM-dd')) < Date.valueOf(((DateTime)selectedDate).format('yyyy-MM-dd'))){ 
            system.debug('Hotfix for European and positive timezone offsets applied.');
            selectedDate = selectedDate.addDays(1);
        }
        */

        Integer timezoneOffsetInMinutes = egTimesheet_Ctlr.getRunningUserTimesoneOffsetInMinutes();
        if( ((DateTime)selectedDate).formatGmt('yyyy-MM-dd')<((DateTime)selectedDate).format('yyyy-MM-dd') ){
            selectedDate = Date.valueOf((((DateTime)selectedDate).addMinutes(timezoneOffsetInMinutes)).format('yyyy-MM-dd'));
        } else if( ((DateTime)selectedDate).formatGmt('yyyy-MM-dd')==((DateTime)selectedDate).format('yyyy-MM-dd') ){
            selectedDate = Date.valueOf(String.valueOf(Date.valueOf((((DateTime)selectedDate).addMinutes(60)).format('yyyy-MM-dd')))); //HOTFIX 20240624: ensure DST hasn't messed things up, this circular valueOf should drop the 01:00 hour shift, if it exists
        }
        System.debug('selectedDate:' + selectedDate);
        //END HOTFIX 20250112

        //Prepare week boundary dates...
        wrapper.timesheetDate = selectedDate;
        Integer selectedDateIsWhatDayOfWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(selectedDate),7); //Sunday = 0, Monday = 1, ...Saturday = 6
        system.debug('selectedDateIsWhatDayOfWeek: ' + selectedDateIsWhatDayOfWeek);
        wrapper.startDate = selectedDate.addDays(-selectedDateIsWhatDayOfWeek); //get to Sunday
        wrapper.endDate = wrapper.startDate.addDays(6); //Saturday in week of selectedDate
        wrapper.startDateString = ((DateTime)wrapper.startDate).formatGmt('M/d/yyyy'); //
        wrapper.endDateString = ((DateTime)wrapper.endDate).formatGmt('M/d/yyyy');

        wrapper.isFuture = (wrapper.startDate > Date.today());

        System.debug('wrapper:' + wrapper);
        
        //Days of week M/d labels...
        wrapper.dates = new List<String>(); 
        for (Integer i = 0; i < 7; i++){
            Date dayOfWeek = wrapper.startDate.addDays(i);
            String dateString = ((DateTime)dayOfWeek).formatGmt('M/d');
            wrapper.dates.add(dateString);
        }

        //Prepare Project/Task grouped rows...
        wrapper.rows = new List<TimesheetRow>();

        //Get or Create Time Card...
        List<EG_Time_Card__c> timeCards = [SELECT Id, Start_Date__c, End_Date__c, Location_Monday__c, Location_Tuesday__c, Location_Wednesday__c, Location_Thursday__c, Location_Friday__c
                                           FROM EG_Time_Card__c 
                                           WHERE OwnerId = :timeCardUserId AND 
                                           Start_Date__c <= :selectedDate AND 
                                           End_Date__c >= :selectedDate];

        System.debug('timeCards:' + timeCards);

        EG_Time_Card__c timeCard;
        if (!timeCards.isEmpty()){
            //We should only ever have 1 Time Card per user per week...
            timeCard = timeCards[0];
        } else {
            //Create a new Time Card for this user for this week...    
            timeCard = new EG_Time_Card__c();
            timeCard.Name = timeCardUser.Name + ': ' + wrapper.startDateString + '-' + wrapper.endDateString; //Time Card naming convention
            timeCard.OwnerId = timeCardUserId;
            timeCard.Start_Date__c = wrapper.startDate;
            timeCard.End_Date__c = wrapper.endDate;
            timeCard.TimeCardExternalId__c = timeCardUserId + '' + timeCard.Start_Date__c;
            if (depts.size() > 0) {
                timeCard.Department__c = depts[0].Id;
            }
            insert timeCard;
        }

        //We have a Time Card, get Time Entries...
        wrapper.timeCard =  timeCard; //added for Working Locations picklists April 2023
        wrapper.timeCardId = timeCard.Id;
        List<EG_Time_Entry__c> entries = [SELECT Id, Date__c, Hours_Worked__c, 
                                          EG_Project__c, EG_Project__r.Name,
                                          EG_Project_Task__c, EG_Project_Task__r.Name
                                          FROM EG_Time_Entry__c 
                                          WHERE EG_Time_Card__c = :timeCard.Id
                                          ORDER BY EG_Project__r.Name, EG_Project_Task__r.Name];

        System.debug('entries:' + entries);

        //Build map of Time Entries by ProjectId:TaskId...
        Map<String, TimesheetRow> rowMap = new Map<String, TimesheetRow>();
        for (EG_Time_Entry__c timeEntry : entries) {
            String key = timeEntry.EG_Project__c+':'+timeEntry.EG_Project_Task__c;

            Integer dayOfWeek = wrapper.startDate.daysBetween(timeEntry.Date__c);

            if (rowMap.containsKey(key)) {
                //Already have a row for this Project:Task, just append hours...
                system.debug('dayOfWeek ' + dayOfWeek);
                rowMap.get(key).hours[dayOfWeek] += timeEntry.Hours_Worked__c;
                rowMap.get(key).cells[dayOfWeek].hours += timeEntry.Hours_Worked__c;
            } else {
                //Create a new row for this Project:Task...
                TimesheetRow timesheetRow = new TimesheetRow();
                
                timesheetRow.projectId = timeEntry.EG_Project__c;
                timesheetRow.projectName = timeEntry.EG_Project__r.Name;
                timesheetRow.noProject = (timeEntry.EG_Project__c == null);

                timesheetRow.taskId = timeEntry.EG_Project_Task__c;
                timesheetRow.taskName = timeEntry.EG_Project_Task__r.Name;
                timesheetRow.noTask = (timeEntry.EG_Project_Task__c == null);

                timesheetRow.hours[dayOfWeek] = timeEntry.Hours_Worked__c;
                timesheetRow.cells[dayOfWeek] = new TimesheetCell(timeEntry.Hours_Worked__c, dayOfWeek);

                rowMap.put(key, timesheetRow);
            }
        }

        //Should we prefill projects and tasks from last week...
        if(prefill){
            //get last week's time card...
            List<EG_Time_Card__c> lastWeekTimeCards = [SELECT Id, OwnerId,
                                                       (SELECT Id, EG_Project__c, EG_Project__r.Name, EG_Project__r.Status__c,
                                                       EG_Project_Task__c, EG_Project_Task__r.Name, EG_Project_Task__r.Status__c
                                                       FROM EG_Time_Entries__r)
                                                       FROM EG_Time_Card__c
                                                       WHERE OwnerId = :timeCardUserId AND 
                                                       Start_Date__c = :wrapper.startDate.addDays(-7)];

            if(lastWeekTimeCards.size()==1){
                EG_Time_Card__c lastWeekTimeCard = lastWeekTimeCards[0];

                if(lastWeekTimeCard.EG_Time_Entries__r!=null && !lastWeekTimeCard.EG_Time_Entries__r.isEmpty()){
                    for(EG_Time_Entry__c timeEntry : lastWeekTimeCard.EG_Time_Entries__r){
                        //An inactive project or task cannot be selected on a new
                        //timesheet, so it must not be copied forward from last week.
                        if(timeEntry.EG_Project__c != null && timeEntry.EG_Project__r.Status__c == 'Inactive') continue;
                        if(timeEntry.EG_Project_Task__c != null && timeEntry.EG_Project_Task__r.Status__c == 'Inactive') continue;

                        String key = timeEntry.EG_Project__c+':'+timeEntry.EG_Project_Task__c;

                        if(!rowMap.containsKey(key)) {
                            //Create a new row for this Project:Task...
                            TimesheetRow timesheetRow = new TimesheetRow();
                            
                            timesheetRow.projectId = timeEntry.EG_Project__c;
                            timesheetRow.projectName = timeEntry.EG_Project__r.Name;
                            timesheetRow.noProject = (timeEntry.EG_Project__c == null);
            
                            timesheetRow.taskId = timeEntry.EG_Project_Task__c;
                            timesheetRow.taskName = timeEntry.EG_Project_Task__r.Name;
                            timesheetRow.noTask = (timeEntry.EG_Project_Task__c == null);
            
                            timesheetRow.hours = new List<Decimal>();
                            timesheetRow.hours.add(0);
                            timesheetRow.hours.add(0);
                            timesheetRow.hours.add(0);
                            timesheetRow.hours.add(0);
                            timesheetRow.hours.add(0);
                            timesheetRow.hours.add(0);
                            timesheetRow.hours.add(0);
                    
                            rowMap.put(key, timesheetRow);
                        }
                    }
                }
            }
        }
        System.debug('rowMap:' + rowMap);

        //User map of rows to create list of rows for wrapper...
        for (String key : rowMap.keySet()) {
            wrapper.rows.add(rowMap.get(key));
        }

        //Add a blank row for UI...
        TimesheetRow blankRow = new TimesheetRow();
        blankRow.hours = new List<Decimal>();
        blankRow.hours.add(0);
        blankRow.hours.add(0);
        blankRow.hours.add(0);
        blankRow.hours.add(0);
        blankRow.hours.add(0);
        blankRow.hours.add(0);
        blankRow.hours.add(0);
        blankRow.noProject = true;
        blankRow.noTask = true;
        wrapper.rows.add(blankRow);

        System.debug('Exiting getTimesheetForDateApex with wrapper: ' + wrapper);
        return wrapper;
    }

    @AuraEnabled
    public static void saveTimesheetApex(Id timeCardId, Id timeCardUserId, Date startDate, List<TimesheetRow> rows, List<String> workingLocations) {
        if(timeCardUserId==null) timeCardUserId = UserInfo.getUserId();

        System.debug('saveTimesheetApex: ' + timeCardId + ',' + timeCardUserId + ',' + startDate + ',' + rows + ',' + workingLocations);

        List<EG_Time_Entry__c> existingEntries = [SELECT Id, ExternalID__c 
                                                  FROM EG_Time_Entry__c 
                                                  WHERE EG_Time_Card__c = :timeCardId];

        Map<String, EG_Time_Entry__c> existingEntryMap = new Map<String, EG_Time_Entry__c>();
        for (EG_Time_Entry__c timeEntry : existingEntries) {
            existingEntryMap.put(timeEntry.ExternalID__c, timeEntry);
        }

        Map<String, Map<Integer, Decimal>> timeMap = new Map<String, Map<Integer, Decimal>>();

        for (TimesheetRow tr : rows) {
            String key = tr.projectId + ':' + tr.taskId;

            if (timeMap.containsKey(key)) {
                
            } else {
                Map<Integer, Decimal> hoursMap = new Map<Integer, Decimal>();
                for (Integer i = 0; i < 7; i++) {
                    hoursMap.put(i, 0);
                }

                timeMap.put(key, hoursMap);
            }

            for (Integer i = 0; i < 7; i++) {

                if (tr.hours[i] != null) {
                    Decimal h = timeMap.get(key).get(i);
                    timeMap.get(key).put(i, h + tr.hours[i]);
                }
                
            }

        }

        System.debug('time map ' + timeMap);

        List<EG_Time_Entry__c> entriesToUpsert = new List<EG_Time_Entry__c>();
        List<EG_Time_Entry__c> entriesToDelete = new List<EG_Time_Entry__c>();
        Set<String> currentEntries = new Set<String>();
        Set<String> projectIds = new Set<String>();
        for (String key : timeMap.keySet()) {
            projectIds.add(key.split(':')[0]);
        }
        Map<Id, EG_Project__c> projectMap = new Map<Id, EG_Project__c>([SELECT Id, Name, Internal_Project__c, Linked_Opportunity__c FROM EG_Project__c WHERE Id in: projectIds ORDER BY Is_Internal__c DESC NULLS FIRST]);
        for (String key : timeMap.keySet()) {
            System.debug('key: '+key);
            String projectId = key.split(':')[0];
            if (projectId == 'null') projectId = null;
            String taskId = key.split(':')[1];
            if (taskId == 'null') taskId = null;

            for (Integer i = 0; i < 7; i++) {

                Date d = startDate.addDays(i);
                String externalId = timeCardId+':'+projectId+':'+taskId+':'+d;

                if (timeMap.get(key).get(i) > 0) {
                    EG_Time_Entry__c timeEntry = new EG_Time_Entry__c();
                    timeEntry.EG_Time_Card__c = timeCardId;
                    timeEntry.EG_Project__c = projectId;
                    timeEntry.Internal__c = projectMap.get(projectId).Internal_Project__c;
                    timeEntry.Opportunity__c = projectMap.get(projectId).Linked_Opportunity__c;
                    timeEntry.EG_Project_Task__c = taskId;
                    timeEntry.Date__c = d;
                    timeEntry.Hours_Worked__c = timeMap.get(key).get(i);
                    timeEntry.ExternalID__c = externalId;
                    if (!existingEntryMap.containsKey(externalId)) {
                        timeEntry.Time_Entry_Source__c = 'Timesheet';
                    }
                    entriesToUpsert.add(timeEntry);
                    currentEntries.add(externalId);
                }
            }
        }

        //update working locations...         
        if(workingLocations!=null && workingLocations.size()==5){
            update new EG_Time_Card__c(Id = timeCardId,
                                       Location_Monday__c = workingLocations[0],
                                       Location_Tuesday__c = workingLocations[1],
                                       Location_Wednesday__c = workingLocations[2],
                                       Location_Thursday__c = workingLocations[3],
                                       Location_Friday__c = workingLocations[4]);
        }       

        //perform upsert...
        if(!entriesToUpsert.isEmpty()) upsert entriesToUpsert ExternalID__c;

        //perform delete...
        for (String s : existingEntryMap.keySet()) {
            if (!currentEntries.contains(s)){
                entriesToDelete.add(existingEntryMap.get(s));
            }
        }
        if(!entriesToDelete.isEmpty()) delete entriesToDelete;

    }

    private static Integer getRunningUserTimesoneOffsetInMinutes(){
        Integer totalOffsetInMinutes = 0;
        try{
            String offset = System.now().format('Z');        
            system.debug('offset: ' + offset);
            Integer offsetSign = (offset.substring(0,1)=='+') ? 1 : -1;
            system.debug('offsetSign: ' + offsetSign);
            Integer offsetHours = Integer.valueOf(offset.substring(1,3));
            system.debug('offsetHours: ' + offsetHours);
            Integer offsetMinutes = Integer.valueOf(offset.substring(3,5));
            system.debug('offsetMinutes: ' + offsetMinutes);

            totalOffsetInMinutes = ((offsetHours * 60) + offsetMinutes) * offsetSign;
        } catch (Exception e){
            system.debug('Exception: ' + e);
        }

        system.debug('totalOffsetInMinutes: ' + totalOffsetInMinutes);
        return totalOffsetInMinutes;
    }

    public class TimesheetWrapper {
        @AuraEnabled public User runningUser {get;set;}
        @AuraEnabled public User timeCardUser {get;set;}
        @AuraEnabled public String timeCardId {get;set;}
        @AuraEnabled public EG_Time_Card__c timeCard {get;set;}
        @AuraEnabled public List<EG_Time_Entry__c> timeEntries {get;set;}
        @AuraEnabled public List<TimesheetRow> rows {get;set;}

        @AuraEnabled public Date timesheetDate {get;set;}

        @AuraEnabled public Date startDate {get;set;}
        @AuraEnabled public String startDateString {get;set;}
        @AuraEnabled public Date endDate {get;set;}
        @AuraEnabled public String endDateString {get;set;}

        @AuraEnabled public Boolean isFuture {get;set;}

        @AuraEnabled public List<String> dates {get;set;}
    }

    public class TimesheetRow {
        @AuraEnabled public Id projectId {get;set;}
        @AuraEnabled public String projectName {get;set;}
        @AuraEnabled public Boolean noProject {get;set;}

        @AuraEnabled public Id taskId {get;set;}
        @AuraEnabled public String taskName {get;set;}
        @AuraEnabled public Boolean noTask {get;set;}

        @AuraEnabled public Integer index {get;set;}
        @AuraEnabled public List<Decimal> hours {get;set;}
        @AuraEnabled public List<TimesheetCell> cells {get;set;}
        
        @AuraEnabled public Decimal sundayHours {get;set;}
        @AuraEnabled public Decimal mondayHours {get;set;}
        @AuraEnabled public Decimal tuesdayHours {get;set;}
        @AuraEnabled public Decimal wednesdayHours {get;set;}
        @AuraEnabled public Decimal thursdayHours {get;set;}
        @AuraEnabled public Decimal fridayHours {get;set;}
        @AuraEnabled public Decimal saturdayHours {get;set;}

        public TimesheetRow(){
            //Constructor
            hours = new List<Decimal>{0,0,0,0,0,0,0};
            cells = new List<TimesheetCell>();
            for (Integer i = 0; i < 7; i++){
                cells.add(new TimesheetCell(0, i));
            }

        }
    }

    public class TimesheetCell{
        @AuraEnabled public Decimal hours {get;set;}
        @AuraEnabled public Integer index {get;set;}

        public TimesheetCell(){
            //Constructor
            hours = 0;
            index = 0;
        }

        public TimesheetCell(Decimal h, Integer i){
            //Constructor
            hours = h;
            index = i;
        }

    }

}