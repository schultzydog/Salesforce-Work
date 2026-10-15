@IsTest
private class OutlookEventReviewControllerTest {

    @IsTest
    static void returnsOwnedEventsWithDayName() {
        Event meeting = new Event(
            Subject = 'My Activity Table Event',
            Type = 'Meeting',
            Activity_Type__c = 'Meeting',
            StartDateTime = Datetime.now().addDays(-1),
            EndDateTime = Datetime.now().addDays(-1).addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(null, null);
        Test.stopTest();

        OutlookEventReviewController.ActivityRow found = findRow(rows, meeting.Id);
        System.assertNotEquals(null, found, 'Owner should see their event');
        System.assertEquals(false, found.hasTimeEntry);
        System.assertEquals(true, String.isNotBlank(found.dayName));
        Event stored = [SELECT StartDateTime FROM Event WHERE Id = :meeting.Id];
        System.assertEquals(
            stored.StartDateTime.getTime(),
            found.startMillis,
            'Past/upcoming uses the event start timestamp, not the calendar day.'
        );
    }

    @IsTest
    static void deletesEvent() {
        Event meeting = new Event(
            Subject = 'Flag Me',
            Type = 'Meeting',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;

        Test.startTest();
        OutlookEventReviewController.deleteEvent(meeting.Id);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Event WHERE Id = :meeting.Id]);
    }

    @IsTest
    static void trashDeletesLinkedTimeEntryAndEvent() {
        Date workDate = Date.today();
        newTimeCard(workDate.toStartOfWeek(), workDate.toStartOfWeek().addDays(6));
        EG_Project__c project = newProject(newOpportunity().Id);
        Event meeting = newMeeting('Trash Both', workDate);

        Test.startTest();
        Id entryId = OutlookEventReviewController.saveTimeEntry(
            meeting.Id, workDate, 2, project.Id, null
        );
        OutlookEventReviewController.deleteEvent(meeting.Id);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Event WHERE Id = :meeting.Id]);
        System.assertEquals(
            0,
            [SELECT COUNT() FROM EG_Time_Entry__c WHERE Id = :entryId],
            'Trash should delete the linked time entry with the event'
        );
    }

    @IsTest
    static void doesNotPrepopulateProjectOnLoad() {
        EG_Project__c project = new EG_Project__c(Name = 'Activity Table Project');
        insert project;

        Event meeting = new Event(
            Subject = 'Project meeting',
            Type = 'Meeting',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addHours(1),
            WhatId = project.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(null, null);
        Test.stopTest();

        OutlookEventReviewController.ActivityRow found = findRow(rows, meeting.Id);
        System.assertEquals(
            null,
            found.suggestedProjectId,
            'The related project must not be guessed on page load.'
        );
        System.assertEquals(null, found.suggestedProjectName);
    }

    @IsTest
    static void ignoresUnlinkedTimeEntryAndSavesLocation() {
        Date weekStart = Date.today().toStartOfWeek();
        Date weekEnd = weekStart.addDays(6);
        EG_Time_Card__c card = newTimeCard(weekStart, weekEnd);
        Opportunity opp = newOpportunity();
        EG_Project__c project = newProject(opp.Id);
        Date workDate = Date.today();
        insert new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1,
            EG_Project__c = project.Id,
            ExternalID__c =
                OutlookEventReviewController.externalIdFor(card.Id, project.Id, null, workDate)
        );

        // Related to the opportunity, not the project: egEventLogic writes its
        // own entry for a project-related event, and with only this test's time
        // card in scope it would build the same unique ExternalID__c.
        Datetime startAt = Datetime.newInstance(workDate, Time.newInstance(10, 0, 0, 0));
        Event meeting = new Event(
            Subject = 'Project meeting on the card',
            Type = 'Meeting',
            StartDateTime = startAt,
            EndDateTime = startAt.addHours(1),
            WhatId = opp.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(null, null);
        // Working location commented out with setWorkingLocation.
        // OutlookEventReviewController.setWorkingLocation(workDate, firstLocationValue());
        // Saturday has no location field, so the call is a no-op.
        // OutlookEventReviewController.setWorkingLocation(Date.newInstance(2026, 1, 3), 'WFH');
        Test.stopTest();

        OutlookEventReviewController.ActivityRow found = findRow(rows, meeting.Id);
        System.assertEquals(
            false,
            found.hasTimeEntry,
            'A same-day entry the event is not linked to must not be adopted.'
        );
        System.assertEquals(null, found.timeEntryId);
    }

    @IsTest
    static void deletesTheTimeEntryLinkedToTheEvent() {
        Date workDate = Date.today();
        newTimeCard(workDate.toStartOfWeek(), workDate.toStartOfWeek().addDays(6));
        EG_Project__c project = newProject(newOpportunity().Id);
        Event meeting = newMeeting('Entry Delete Event', workDate);

        Test.startTest();
        Id entryId = OutlookEventReviewController.saveTimeEntry(
            meeting.Id, workDate, 2, project.Id, null
        );
        OutlookEventReviewController.deleteTimeEntryForEvent(meeting.Id);
        // A second call is a no-op now that nothing is linked.
        OutlookEventReviewController.deleteTimeEntryForEvent(meeting.Id);
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM EG_Time_Entry__c WHERE Id = :entryId],
            'The linked entry should be deleted'
        );
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM EG_Time_Entry__c
                WHERE Source_Event_Id__c = :String.valueOf(meeting.Id)
            ],
            'Nothing should still claim the event'
        );
    }

    @IsTest
    static void retagsTheLinkedEntryWithoutReplacingIt() {
        Date workDate = Date.today();
        EG_Time_Card__c card = newTimeCard(workDate.toStartOfWeek(), workDate.toStartOfWeek().addDays(6));
        EG_Project__c project = newProject(null);
        EG_Project_Task__c first = newProjectTask(project.Id);
        EG_Project_Task__c second = new EG_Project_Task__c(
            Name = 'Second Task', EG_Project__c = project.Id
        );
        insert second;
        Event meeting = newMeeting('Retag me', workDate);

        Test.startTest();
        Id entryId = OutlookEventReviewController.saveTimeEntry(
            meeting.Id, workDate, 3, project.Id, first.Id
        );
        Id afterSwap = OutlookEventReviewController.updateTimeEntryTask(meeting.Id, second.Id);
        Id afterClear = OutlookEventReviewController.updateTimeEntryTask(meeting.Id, null);
        Test.stopTest();

        System.assertEquals(entryId, afterSwap, 'Swapping the task must reuse the record');
        System.assertEquals(entryId, afterClear, 'Clearing the task must reuse the record');
        System.assertEquals(
            1,
            [SELECT COUNT() FROM EG_Time_Entry__c],
            'No duplicate entry should be created'
        );
        EG_Time_Entry__c stored = [
            SELECT EG_Project_Task__c, Hours_Worked__c, Source_Event_Id__c
            FROM EG_Time_Entry__c
            WHERE Id = :entryId
        ];
        System.assertEquals(null, stored.EG_Project_Task__c, 'Entries are valid with no task');
        System.assertEquals(3, stored.Hours_Worked__c, 'Hours must survive the retag');
        System.assertEquals(
            String.valueOf(meeting.Id),
            stored.Source_Event_Id__c,
            'The retagged entry must keep its claim on the event.'
        );
    }

    @IsTest
    static void updateTimeEntryTaskRejectsBadInput() {
        Date workDate = Date.today();
        newTimeCard(workDate.toStartOfWeek(), workDate.toStartOfWeek().addDays(6));
        EG_Project__c project = newProject(null);
        EG_Project__c other = new EG_Project__c(Name = 'Other Project');
        insert other;
        EG_Project_Task__c foreignTask = new EG_Project_Task__c(
            Name = 'Foreign Task', EG_Project__c = other.Id
        );
        insert foreignTask;
        Event meeting = newMeeting('Bad retag', workDate);

        Test.startTest();
        // Nothing linked yet, so there is nothing to retag.
        System.assertEquals(
            null,
            OutlookEventReviewController.updateTimeEntryTask(meeting.Id, null),
            'An unlinked event returns null so the caller can create instead'
        );
        OutlookEventReviewController.saveTimeEntry(meeting.Id, workDate, 1, project.Id, null);
        try {
            OutlookEventReviewController.updateTimeEntryTask(meeting.Id, foreignTask.Id);
            System.assert(false, 'A task from another project should fail');
        } catch (Exception error) {
            System.assertEquals(true, error instanceof AuraHandledException);
        }
        try {
            OutlookEventReviewController.updateTimeEntryTask(project.Id, null);
            System.assert(false, 'A non-event id should fail');
        } catch (Exception error) {
            System.assertEquals(true, error instanceof AuraHandledException);
        }
        Test.stopTest();
    }

    @IsTest
    static void deleteTimeEntryForEventRejectsBadInput() {
        Account account = new Account(Name = 'Not An Event Co');
        insert account;
        Test.startTest();
        try {
            OutlookEventReviewController.deleteTimeEntryForEvent(account.Id);
            System.assert(false, 'A non-event id should fail');
        } catch (Exception error) {
            System.assertEquals(true, error instanceof AuraHandledException);
        }
        Test.stopTest();
    }

    @IsTest
    static void returnsActiveProjectsForAnAccountUpToTwo() {
        Account account = new Account(Name = 'Single Project Co');
        insert account;

        Test.startTest();
        List<EG_Project__c> none = OutlookEventReviewController.activeProjectsForAccount(account.Id);
        insert new EG_Project__c(
            Name = 'Only Active Project', Account__c = account.Id, Status__c = 'Active'
        );
        List<EG_Project__c> one = OutlookEventReviewController.activeProjectsForAccount(account.Id);
        insert new EG_Project__c(
            Name = 'Second Active Project', Account__c = account.Id, Status__c = 'Active'
        );
        List<EG_Project__c> two = OutlookEventReviewController.activeProjectsForAccount(account.Id);
        List<EG_Project__c> blank = OutlookEventReviewController.activeProjectsForAccount(null);
        List<EG_Project__c> wrongType =
            OutlookEventReviewController.activeProjectsForAccount(account.OwnerId);
        Test.stopTest();

        System.assertEquals(0, none.size(), 'No projects yet');
        System.assertEquals(1, one.size(), 'Exactly one active project is detectable');
        System.assertEquals('Only Active Project', one[0].Name);
        System.assertEquals(2, two.size(), 'More than one stops the autopopulate');
        System.assertEquals(0, blank.size());
        System.assertEquals(0, wrongType.size());
    }

    @IsTest
    static void dateRangeExcludesOldEvents() {
        Datetime oldStart = Datetime.now().addDays(-200);
        insert new Event(
            Subject = 'Too old',
            Type = 'Meeting',
            StartDateTime = oldStart,
            EndDateTime = oldStart.addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        Datetime recentStart = Datetime.now();
        Event recent = new Event(
            Subject = 'Recent meeting',
            Type = 'Meeting',
            StartDateTime = recentStart,
            EndDateTime = recentStart.addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert recent;

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(Date.today().addDays(-7), Date.today().addDays(1));
        Test.stopTest();

        System.assertEquals(null, findRow(rows, [SELECT Id FROM Event WHERE Subject = 'Too old' LIMIT 1].Id));
        System.assertNotEquals(null, findRow(rows, recent.Id));
    }

    @IsTest
    static void savesNewTimeEntryAndLinksEvent() {
        Date workDate = Date.today();
        EG_Time_Card__c card = newTimeCard(workDate.toStartOfWeek(), workDate.toStartOfWeek().addDays(6));
        EG_Project__c project = newProject(null);
        EG_Project_Task__c task = newProjectTask(project.Id);
        Event meeting = newMeeting('Log me', workDate);

        Test.startTest();
        Id entryId = OutlookEventReviewController.saveTimeEntry(
            meeting.Id, workDate, 1.5, project.Id, task.Id
        );
        Test.stopTest();

        EG_Time_Entry__c stored = [
            SELECT EG_Time_Card__c, Date__c, Hours_Worked__c, EG_Project__c,
                   EG_Project_Task__c, Created_with_Automation__c,
                   Time_Entry_Source__c, Source_Event_Id__c, ExternalID__c
            FROM EG_Time_Entry__c
            WHERE Id = :entryId
        ];
        System.assertEquals(card.Id, stored.EG_Time_Card__c);
        System.assertEquals(1.5, stored.Hours_Worked__c);
        System.assertEquals(project.Id, stored.EG_Project__c);
        System.assertEquals(task.Id, stored.EG_Project_Task__c);
        System.assertEquals(false, stored.Created_with_Automation__c);
        System.assertEquals('Event_Review_Page', stored.Time_Entry_Source__c);
        System.assertEquals(
            String.valueOf(meeting.Id),
            stored.Source_Event_Id__c,
            'Saving should stamp the event onto the entry.'
        );
        System.assertEquals(
            card.Id + ':' + project.Id + ':' + task.Id + ':' + workDate
                + ':' + meeting.Id + ':' + UserInfo.getUserEmail(),
            stored.ExternalID__c,
            'ExternalID is card:project:task:date:eventId:userEmail.'
        );
    }

    @IsTest
    static void twoMeetingsSameProjectTaskDayEachGetTheirOwnEntry() {
        Date workDate = Date.today();
        newTimeCard(workDate.toStartOfWeek(), workDate.toStartOfWeek().addDays(6));
        EG_Project__c project = newProject(null);
        EG_Project_Task__c task = newProjectTask(project.Id);
        Event morning = newMeeting('Morning', workDate);
        Event afternoon = newMeeting('Afternoon', workDate);

        Test.startTest();
        Id morningEntry = OutlookEventReviewController.saveTimeEntry(
            morning.Id, workDate, 1, project.Id, task.Id
        );
        Id afternoonEntry = OutlookEventReviewController.saveTimeEntry(
            afternoon.Id, workDate, 2, project.Id, task.Id
        );
        Test.stopTest();

        System.assertNotEquals(morningEntry, afternoonEntry);
        System.assertEquals(2, [SELECT COUNT() FROM EG_Time_Entry__c]);
        System.assertEquals(
            String.valueOf(morning.Id),
            [SELECT Source_Event_Id__c FROM EG_Time_Entry__c WHERE Id = :morningEntry]
                .Source_Event_Id__c
        );
        System.assertEquals(
            String.valueOf(afternoon.Id),
            [SELECT Source_Event_Id__c FROM EG_Time_Entry__c WHERE Id = :afternoonEntry]
                .Source_Event_Id__c
        );
    }

    @IsTest
    static void updatesEntryTheAutomationAlreadyDrafted() {
        Date workDate = Date.today();
        EG_Time_Card__c card = newTimeCard(workDate.toStartOfWeek(), workDate.toStartOfWeek().addDays(6));
        EG_Project__c project = newProject(null);
        Event meeting = newMeeting('Already drafted', workDate);
        // Linked by Source_Event_Id__c — that is what saveTimeEntry matches on.
        // ExternalID__c is irrelevant to the find path.
        EG_Time_Entry__c drafted = new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1,
            EG_Project__c = project.Id,
            Source_Event_Id__c = String.valueOf(meeting.Id),
            Created_with_Automation__c = true,
            Time_Entry_Source__c = 'Automation'
        );
        insert drafted;

        Test.startTest();
        Id entryId = OutlookEventReviewController.saveTimeEntry(
            meeting.Id, workDate, 2.25, project.Id, null
        );
        Test.stopTest();

        System.assertEquals(drafted.Id, entryId, 'Should reuse the drafted entry');
        System.assertEquals(1, [SELECT COUNT() FROM EG_Time_Entry__c]);
        EG_Time_Entry__c stored = [
            SELECT Hours_Worked__c, Created_with_Automation__c, Time_Entry_Source__c
            FROM EG_Time_Entry__c
            WHERE Id = :entryId
        ];
        System.assertEquals(2.25, stored.Hours_Worked__c);
        System.assertEquals(
            true,
            stored.Created_with_Automation__c,
            'Updating hours should leave the automation flag alone.'
        );
        System.assertEquals(
            'Automation',
            stored.Time_Entry_Source__c,
            'Updating hours should leave the original source alone.'
        );
    }

    @IsTest
    static void saveTimeEntryRejectsBadInput() {
        Date workDate = Date.today();
        EG_Project__c project = newProject(null);
        EG_Project__c otherProject = newProject(null);
        EG_Project_Task__c foreignTask = newProjectTask(otherProject.Id);
        Event meeting = newMeeting('Bad input', workDate);

        Test.startTest();
        assertSaveFails(null, workDate, 1, project.Id, null, 'null event');
        assertSaveFails(meeting.Id, null, 1, project.Id, null, 'null date');
        assertSaveFails(meeting.Id, workDate, 0, project.Id, null, 'zero hours');
        assertSaveFails(meeting.Id, workDate, 1, null, null, 'missing project');
        assertSaveFails(
            meeting.Id, workDate, 1, project.Id, foreignTask.Id, 'task from another project'
        );
        // Valid input, but no time card covers the week.
        assertSaveFails(meeting.Id, workDate, 1, project.Id, null, 'missing time card');
        Test.stopTest();
    }

    private static void assertSaveFails(
        Id eventId,
        Date workDate,
        Decimal hours,
        Id projectId,
        Id projectTaskId,
        String scenario
    ) {
        try {
            OutlookEventReviewController.saveTimeEntry(
                eventId, workDate, hours, projectId, projectTaskId
            );
            System.assert(false, scenario + ' should fail');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
    }

    @IsTest
    static void returnsContactsAndLeadsRelatedToTheEvent() {
        Account account = new Account(Name = 'Attendee Co');
        insert account;
        Contact primary = new Contact(
            LastName = 'Smith',
            FirstName = 'Jane',
            AccountId = account.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert primary;
        Lead invitee = new Lead(LastName = 'Doe', FirstName = 'John', Company = 'Doe Co');
        insert invitee;
        Event meeting = newMeeting('Attendee Event', Date.today().addDays(-1));
        meeting.WhoId = primary.Id;
        update meeting;
        insert new EventRelation(EventId = meeting.Id, RelationId = invitee.Id);

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(null, null);
        Test.stopTest();

        OutlookEventReviewController.ActivityRow found = findRow(rows, meeting.Id);
        System.assertNotEquals(null, found, 'Event should be returned');
        Set<Id> attendeeIds = new Set<Id>();
        for (OutlookEventReviewController.RelatedPerson person : found.attendees) {
            attendeeIds.add(person.id);
            System.assertEquals('/' + person.id, person.url, 'Attendee should link to its record');
            System.assertEquals(true, String.isNotBlank(person.name));
        }
        System.assertEquals(true, attendeeIds.contains(primary.Id), 'Primary contact is listed');
        System.assertEquals(true, attendeeIds.contains(invitee.Id), 'Invited lead is listed');
    }

    @IsTest
    static void updatesEventAccountAndReportsItOnTheRow() {
        Account account = new Account(Name = 'Account Column Co');
        insert account;
        Event meeting = newMeeting('Account Edit Event', Date.today().addDays(-1));

        Test.startTest();
        OutlookEventReviewController.updateEventAccount(meeting.Id, account.Id);
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(null, null);
        Test.stopTest();

        Event stored = [SELECT WhatId FROM Event WHERE Id = :meeting.Id];
        System.assertEquals(account.Id, stored.WhatId, 'Account is stored on WhatId');
        OutlookEventReviewController.ActivityRow found = findRow(rows, meeting.Id);
        System.assertEquals(account.Id, found.accountId);
        System.assertEquals('Account Column Co', found.accountName);
    }

    @IsTest
    static void updateEventAccountRejectsBadInput() {
        Account account = new Account(Name = 'Wrong Type Co');
        insert account;
        Event meeting = newMeeting('Bad Input Event', Date.today().addDays(-1));

        Test.startTest();
        try {
            OutlookEventReviewController.updateEventAccount(null, account.Id);
            System.assert(false, 'A missing event should fail');
        } catch (Exception error) {
            System.assertEquals(true, error instanceof AuraHandledException);
        }
        try {
            OutlookEventReviewController.updateEventAccount(meeting.Id, meeting.Id);
            System.assert(false, 'A non-account value should fail');
        } catch (Exception error) {
            System.assertEquals(true, error instanceof AuraHandledException);
        }
        Test.stopTest();
    }

    private static Event newMeeting(String subject, Date workDate) {
        Datetime startAt = Datetime.newInstance(workDate, Time.newInstance(10, 0, 0, 0));
        Event meeting = new Event(
            Subject = subject,
            Type = 'Meeting',
            StartDateTime = startAt,
            EndDateTime = startAt.addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;
        return meeting;
    }

    private static EG_Time_Card__c newTimeCard(Date weekStart, Date weekEnd) {
        EG_Time_Card__c card = new EG_Time_Card__c(
            Name = 'Test Time Card',
            Start_Date__c = weekStart,
            End_Date__c = weekEnd
        );
        insert card;
        return card;
    }

    private static Opportunity newOpportunity() {
        Opportunity opp = new Opportunity(
            Name = 'Outlook Event Review Opp',
            StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true LIMIT 1].MasterLabel,
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    private static EG_Project__c newProject(Id opportunityId) {
        EG_Project__c project = new EG_Project__c(
            Name = 'Outlook Event Review Project',
            Linked_Opportunity__c = opportunityId
        );
        insert project;
        return project;
    }

    private static EG_Project_Task__c newProjectTask(Id projectId) {
        EG_Project_Task__c task = new EG_Project_Task__c(
            Name = 'Outlook Event Review Task',
            EG_Project__c = projectId
        );
        insert task;
        return task;
    }

    @IsTest
    static void findsMatchingEventBySubjectAndStart() {
        Account account = new Account(Name = 'Panel Match Account');
        insert account;
        Datetime startAt = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0));
        Event meeting = new Event(
            Subject = 'Panel Match Meeting',
            Type = 'Meeting',
            StartDateTime = startAt,
            EndDateTime = startAt.addHours(1),
            WhatId = account.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;
        String startIso = JSON.serialize(startAt).replace('"', '');

        Test.startTest();
        OutlookEventReviewController.MatchingEvent match =
            OutlookEventReviewController.findMatchingEvent('Panel Match Meeting', startIso);
        OutlookEventReviewController.MatchingEvent missing =
            OutlookEventReviewController.findMatchingEvent('Some other subject', startIso);
        OutlookEventReviewController.MatchingEvent noDate =
            OutlookEventReviewController.findMatchingEvent('Panel Match Meeting', null);
        Test.stopTest();

        System.assertNotEquals(null, match, 'Should find the owned meeting');
        System.assertEquals(meeting.Id, match.id);
        System.assertEquals(account.Id, match.accountId);
        System.assertEquals(null, missing);
        System.assertEquals(null, noDate);
    }

    @IsTest
    static void panelMatchDoesNotGuessProjectFromRelatedRecords() {
        Opportunity opp = newOpportunity();
        // A project hanging off the opportunity used to seed the panel.
        newProject(opp.Id);
        Datetime startAt = Datetime.newInstance(Date.today(), Time.newInstance(13, 0, 0, 0));
        Event meeting = new Event(
            Subject = 'No Guess Meeting',
            Type = 'Meeting',
            StartDateTime = startAt,
            EndDateTime = startAt.addHours(1),
            WhatId = opp.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;
        String startIso = JSON.serialize(startAt).replace('"', '');

        Test.startTest();
        OutlookEventReviewController.MatchingEvent match =
            OutlookEventReviewController.findMatchingEvent('No Guess Meeting', startIso);
        Test.stopTest();

        System.assertNotEquals(null, match, 'The Salesforce event should still be found');
        System.assertEquals(meeting.Id, match.id);
        System.assertEquals(
            null,
            match.suggestedProjectId,
            'A related opportunity must not seed a project on the panel.'
        );
        System.assertEquals(null, match.projectTaskId);
        System.assertEquals(null, match.timeEntryId);
        System.assertEquals(null, match.hours);
        System.assertEquals(null, match.notes);
    }

    @IsTest
    static void panelMatchReturnsTheLinkedEntryForEditing() {
        Date workDate = Date.today();
        newTimeCard(workDate.toStartOfWeek(), workDate.toStartOfWeek().addDays(6));
        EG_Project__c project = newProject(null);
        EG_Project_Task__c task = newProjectTask(project.Id);
        Datetime startAt = Datetime.newInstance(workDate, Time.newInstance(14, 0, 0, 0));
        Event meeting = new Event(
            Subject = 'Linked Entry Meeting',
            Type = 'Meeting',
            StartDateTime = startAt,
            EndDateTime = startAt.addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;
        Id entryId = OutlookEventReviewController.saveTimeEntry(
            meeting.Id, workDate, 2.5, project.Id, task.Id
        );
        update new EG_Time_Entry__c(Id = entryId, Notes__c = 'Panel notes');
        String startIso = JSON.serialize(startAt).replace('"', '');

        Test.startTest();
        OutlookEventReviewController.MatchingEvent match =
            OutlookEventReviewController.findMatchingEvent('Linked Entry Meeting', startIso);
        Test.stopTest();

        System.assertNotEquals(null, match);
        System.assertEquals(entryId, match.timeEntryId, 'The panel edits the linked entry');
        System.assertEquals(project.Id, match.suggestedProjectId);
        System.assertEquals(task.Id, match.projectTaskId);
        System.assertEquals(2.5, match.hours, 'Hours come from the linked entry');
        System.assertEquals('Panel notes', match.notes);
        System.assertEquals(true, String.isNotBlank(match.suggestedProjectName));
        System.assertEquals(true, String.isNotBlank(match.projectTaskName));
    }

    @IsTest
    static void linksEventToTimeEntry() {
        Date workDate = Date.today();
        EG_Time_Card__c card = newTimeCard(workDate.toStartOfWeek(), workDate.toStartOfWeek().addDays(6));
        EG_Project__c project = newProject(null);
        EG_Time_Entry__c entry = new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1,
            EG_Project__c = project.Id,
            ExternalID__c =
                OutlookEventReviewController.externalIdFor(card.Id, project.Id, null, workDate)
        );
        insert entry;
        Event meeting = newMeeting('Link me', workDate);

        Test.startTest();
        OutlookEventReviewController.linkEventTimeEntry(meeting.Id, entry.Id);
        Test.stopTest();

        System.assertEquals(
            String.valueOf(meeting.Id),
            [SELECT Source_Event_Id__c FROM EG_Time_Entry__c WHERE Id = :entry.Id]
                .Source_Event_Id__c
        );
        try {
            OutlookEventReviewController.linkEventTimeEntry(null, entry.Id);
            System.assert(false, 'null event should fail');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
        try {
            OutlookEventReviewController.linkEventTimeEntry(meeting.Id, null);
            System.assert(false, 'null time entry should fail');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
    }

    @IsTest
    static void locationAndFlagRejectBadInput() {
        Test.startTest();
        // Working location commented out with setWorkingLocation.
        // try {
        //     OutlookEventReviewController.setWorkingLocation(null, 'WFH');
        //     System.assert(false, 'null date should fail');
        // } catch (AuraHandledException expected) {
        //     System.assert(true);
        // }
        // try {
        //     OutlookEventReviewController.setWorkingLocation(Date.newInstance(2010, 1, 4), 'WFH');
        //     System.assert(false, 'missing time card should fail');
        // } catch (AuraHandledException expected) {
        //     System.assert(true);
        // }
        try {
            OutlookEventReviewController.deleteEvent(null);
            System.assert(false, 'null record should fail');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
        try {
            OutlookEventReviewController.deleteEvent(UserInfo.getUserId());
            System.assert(false, 'non-event should fail');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
        Test.stopTest();
    }

    // private static String firstLocationValue() {
    //     for (Schema.PicklistEntry entry : EG_Time_Card__c.Location_Monday__c.getDescribe().getPicklistValues()) {
    //         if (entry.isActive()) {
    //             return entry.getValue();
    //         }
    //     }
    //     return null;
    // }

    private static OutlookEventReviewController.ActivityRow findRow(
        List<OutlookEventReviewController.ActivityRow> rows,
        Id recordId
    ) {
        for (OutlookEventReviewController.ActivityRow row : rows) {
            if (row.id == recordId) {
                return row;
            }
        }
        return null;
    }
}
