/**
 * @description Unit tests for TimeEntryService. Covers the happy path (including
 * the automation flag and external-id mapping), the missing-card branch, and
 * input validation.
 */
@IsTest
private class TimeEntryServiceTest {
    @IsTest
    static void createEntry_whenCardExists_createsAutomationEntry() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );

        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.newInstance(2026, 1, 7);
        request.hoursWorked = 2.5;
        request.notes = 'Client call';
        request.timeCategory = TestDataFactory.firstTimeCategory();
        request.internal = false;
        request.externalId = 'OUTLOOK-EVENT-123';

        Test.startTest();
        TimeEntryService.TimeEntryResult result = new TimeEntryService().createEntry(request);
        Test.stopTest();

        System.assertNotEquals(null, result.timeEntryId, 'An entry Id should be returned.');
        System.assertEquals(card.Id, result.timeCardId, 'The result should reference the covering card.');

        EG_Time_Entry__c entry = [
            SELECT EG_Time_Card__c, Date__c, Hours_Worked__c, Notes__c,
                   Internal__c, Created_with_Automation__c, ExternalID__c,
                   Time_Entry_Source__c
            FROM EG_Time_Entry__c
            WHERE Id = :result.timeEntryId
        ];
        System.assertEquals(card.Id, entry.EG_Time_Card__c, 'Entry should be under the covering card.');
        System.assertEquals(Date.newInstance(2026, 1, 7), entry.Date__c, 'Date should match the request.');
        System.assertEquals(2.5, entry.Hours_Worked__c, 'Hours should match the request.');
        System.assertEquals('Client call', entry.Notes__c, 'Notes should match the request.');
        System.assertEquals(false, entry.Internal__c, 'Internal should match the request.');
        System.assertEquals(true, entry.Created_with_Automation__c, 'Entry should be flagged as automation-created.');
        System.assertEquals('Outlook_Panel', entry.Time_Entry_Source__c, 'Panel creates should stamp Outlook Panel.');
        System.assertEquals('OUTLOOK-EVENT-123', entry.ExternalID__c, 'External id should be stored.');
        System.assertEquals(false, result.wasUpdated, 'A brand-new entry is a create, not an update.');
    }

    @IsTest
    static void createEntry_whenNoExternalIdSupplied_stampsCanonicalKey() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c project = TestDataFactory.newProject(opp.Id);

        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.newInstance(2026, 1, 7);
        request.hoursWorked = 3;
        request.projectId = project.Id;

        Test.startTest();
        TimeEntryService.TimeEntryResult result = new TimeEntryService().createEntry(request);
        Test.stopTest();

        EG_Time_Entry__c entry = [
            SELECT ExternalID__c FROM EG_Time_Entry__c WHERE Id = :result.timeEntryId
        ];
        System.assertEquals(
            TimeEntryKey.build(card.Id, project.Id, null, Date.newInstance(2026, 1, 7)),
            entry.ExternalID__c,
            'The canonical key should be derived when the caller supplies none.'
        );
    }

    @IsTest
    static void createEntry_whenKeyAlreadyExists_updatesInsteadOfDuplicating() {
        TestDataFactory.newTimeCard(Date.newInstance(2026, 1, 5), Date.newInstance(2026, 1, 11));
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c project = TestDataFactory.newProject(opp.Id);

        TimeEntryRequest first = new TimeEntryRequest();
        first.workDate = Date.newInstance(2026, 1, 7);
        first.hoursWorked = 1;
        first.notes = 'Initial';
        first.projectId = project.Id;
        TimeEntryService.TimeEntryResult created = new TimeEntryService().createEntry(first);

        TimeEntryRequest second = new TimeEntryRequest();
        second.workDate = Date.newInstance(2026, 1, 7);
        second.hoursWorked = 4.5;
        second.notes = 'Corrected';
        second.projectId = project.Id;

        Test.startTest();
        TimeEntryService.TimeEntryResult updated = new TimeEntryService().createEntry(second);
        Test.stopTest();

        System.assertEquals(created.timeEntryId, updated.timeEntryId, 'The same entry should be reused.');
        System.assertEquals(true, updated.wasUpdated, 'The result should report an update.');

        List<EG_Time_Entry__c> entries = [
            SELECT Hours_Worked__c, Notes__c FROM EG_Time_Entry__c
        ];
        System.assertEquals(1, entries.size(), 'A second submit must not create a duplicate.');
        System.assertEquals(4.5, entries[0].Hours_Worked__c, 'Hours should be replaced, not summed.');
        System.assertEquals('Corrected', entries[0].Notes__c, 'Notes should be replaced.');
    }

    @IsTest
    static void createEntry_whenAutomationDraftExists_updatesItWithoutBlankingNotes() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c project = TestDataFactory.newProject(opp.Id);
        Date workDate = Date.newInstance(2026, 1, 7);

        // Stand in for the entry egEventLogic writes when the Outlook event syncs.
        EG_Time_Entry__c draft = new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1,
            Notes__c = 'Auto-generated from meeting',
            EG_Project__c = project.Id,
            ExternalID__c = TimeEntryKey.build(card.Id, project.Id, null, workDate),
            Time_Entry_Source__c = 'Automation'
        );
        insert draft;

        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = workDate;
        request.hoursWorked = 2;
        request.projectId = project.Id; // user leaves notes untouched

        Test.startTest();
        TimeEntryService.TimeEntryResult result = new TimeEntryService().createEntry(request);
        Test.stopTest();

        System.assertEquals(draft.Id, result.timeEntryId, 'The panel should edit the automation draft.');
        EG_Time_Entry__c entry = [
            SELECT Hours_Worked__c, Notes__c, Time_Entry_Source__c FROM EG_Time_Entry__c WHERE Id = :draft.Id
        ];
        System.assertEquals(2, entry.Hours_Worked__c, 'Hours should reflect the panel submission.');
        System.assertEquals(
            'Automation',
            entry.Time_Entry_Source__c,
            'Panel edits must not overwrite the original source.'
        );
        System.assertEquals(
            'Auto-generated from meeting',
            entry.Notes__c,
            'Blank notes in the request must not wipe the existing value.'
        );
    }

    @IsTest
    static void createEntry_whenNoCard_throwsNotFound() {
        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.newInstance(2026, 3, 3);
        request.hoursWorked = 1;

        Test.startTest();
        try {
            new TimeEntryService().createEntry(request);
            System.assert(false, 'Expected a TimeCardNotFoundException.');
        } catch (TimeEntryService.TimeCardNotFoundException e) {
            System.assert(
                e.getMessage().contains('No time card'),
                'Unexpected message: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void createEntry_whenNullRequest_throwsIllegalArgument() {
        try {
            new TimeEntryService().createEntry(null);
            System.assert(false, 'Expected an IllegalArgumentException.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Null request rejected as expected.');
        }
    }

    @IsTest
    static void createEntry_whenHoursNotPositive_throwsIllegalArgument() {
        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.today();
        request.hoursWorked = 0;

        try {
            new TimeEntryService().createEntry(request);
            System.assert(false, 'Expected an IllegalArgumentException.');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Non-positive hours rejected as expected.');
        }
    }

    @IsTest
    static void createEntry_withFullHierarchy_setsAllLookups() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c project = TestDataFactory.newProject(opp.Id);
        EG_Project_Task__c task = TestDataFactory.newProjectTask(project.Id);

        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.newInstance(2026, 1, 7);
        request.hoursWorked = 4;
        request.opportunityId = opp.Id;
        request.projectId = project.Id;
        request.projectTaskId = task.Id;

        Test.startTest();
        TimeEntryService.TimeEntryResult result = new TimeEntryService().createEntry(request);
        Test.stopTest();

        EG_Time_Entry__c entry = [
            SELECT Opportunity__c, EG_Project__c, EG_Project_Task__c
            FROM EG_Time_Entry__c
            WHERE Id = :result.timeEntryId
        ];
        System.assertEquals(opp.Id, entry.Opportunity__c, 'Opportunity should be set.');
        System.assertEquals(project.Id, entry.EG_Project__c, 'Project should be set.');
        System.assertEquals(task.Id, entry.EG_Project_Task__c, 'Task should be set.');
    }

    @IsTest
    static void createEntry_withTaskOnly_derivesProjectAndOpportunity() {
        TestDataFactory.newTimeCard(Date.newInstance(2026, 1, 5), Date.newInstance(2026, 1, 11));
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c project = TestDataFactory.newProject(opp.Id);
        EG_Project_Task__c task = TestDataFactory.newProjectTask(project.Id);

        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.newInstance(2026, 1, 7);
        request.hoursWorked = 1;
        request.projectTaskId = task.Id; // no project or opportunity supplied

        Test.startTest();
        TimeEntryService.TimeEntryResult result = new TimeEntryService().createEntry(request);
        Test.stopTest();

        EG_Time_Entry__c entry = [
            SELECT Opportunity__c, EG_Project__c, EG_Project_Task__c
            FROM EG_Time_Entry__c
            WHERE Id = :result.timeEntryId
        ];
        System.assertEquals(project.Id, entry.EG_Project__c, 'Project should be derived from the task.');
        System.assertEquals(opp.Id, entry.Opportunity__c, 'Opportunity should be derived from the project.');
    }

    @IsTest
    static void getEntriesForDate_returnsEntriesWithResolvedNames() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c project = TestDataFactory.newProject(opp.Id);
        EG_Project_Task__c task = TestDataFactory.newProjectTask(project.Id);
        Date workDate = Date.newInstance(2026, 1, 7);

        insert new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1,
            EG_Project__c = project.Id,
            EG_Project_Task__c = task.Id,
            Created_with_Automation__c = true
        );
        // Different day: must not appear in the list.
        insert new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = Date.newInstance(2026, 1, 8),
            Hours_Worked__c = 2
        );

        Test.startTest();
        List<TimeEntrySummary> summaries = new TimeEntryService().getEntriesForDate(workDate);
        Test.stopTest();

        System.assertEquals(1, summaries.size(), 'Only the entry on the requested date should return.');
        System.assertEquals(project.Id, summaries[0].projectId, 'Project should be included.');
        System.assertEquals('POC Test Project', summaries[0].projectName, 'Project name should resolve.');
        System.assertEquals('POC Test Task', summaries[0].projectTaskName, 'Task name should resolve.');
        System.assertEquals(true, summaries[0].createdWithAutomation, 'Automation flag should be exposed.');
    }

    @IsTest
    static void getEntriesForDate_whenNoCard_returnsEmpty() {
        Test.startTest();
        List<TimeEntrySummary> summaries = new TimeEntryService()
            .getEntriesForDate(Date.newInstance(2026, 4, 1));
        Test.stopTest();

        System.assertEquals(0, summaries.size(), 'No card means nothing to edit.');
    }

    @IsTest
    static void getEntriesForDate_whenNullDate_returnsEmpty() {
        System.assertEquals(
            0,
            new TimeEntryService().getEntriesForDate(null).size(),
            'A null date should be handled without querying.'
        );
    }

    @IsTest
    static void createEntry_withTargetedEntry_updatesThatRecordAndRestampsKey() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c project = TestDataFactory.newProject(opp.Id);
        Date workDate = Date.newInstance(2026, 1, 7);

        // An automation draft with no project yet -- the case the panel exists to fix.
        EG_Time_Entry__c draft = new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1,
            Notes__c = 'Auto-generated',
            ExternalID__c = TimeEntryKey.build(card.Id, null, null, workDate)
        );
        insert draft;

        TimeEntryRequest request = new TimeEntryRequest();
        request.timeEntryId = draft.Id;
        request.workDate = workDate;
        request.hoursWorked = 2.75;
        request.notes = 'Reviewed by user';
        request.projectId = project.Id;

        Test.startTest();
        TimeEntryService.TimeEntryResult result = new TimeEntryService().createEntry(request);
        Test.stopTest();

        System.assertEquals(draft.Id, result.timeEntryId, 'The targeted entry should be updated.');
        System.assertEquals(true, result.wasUpdated, 'The result should report an update.');

        EG_Time_Entry__c entry = [
            SELECT Hours_Worked__c, Notes__c, EG_Project__c, Opportunity__c, ExternalID__c
            FROM EG_Time_Entry__c
            WHERE Id = :draft.Id
        ];
        System.assertEquals(2.75, entry.Hours_Worked__c, 'Hours should be replaced.');
        System.assertEquals('Reviewed by user', entry.Notes__c, 'Notes should be written verbatim.');
        System.assertEquals(project.Id, entry.EG_Project__c, 'The chosen project should be applied.');
        System.assertEquals(opp.Id, entry.Opportunity__c, 'Opportunity should be back-filled.');
        System.assertEquals(
            TimeEntryKey.build(card.Id, project.Id, null, workDate),
            entry.ExternalID__c,
            'The key should be re-stamped to describe the entry’s new values.'
        );
    }

    @IsTest
    static void createEntry_whenTargetedEditCollidesWithAnotherKey_throwsInvalidSelection() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c project = TestDataFactory.newProject(opp.Id);
        Date workDate = Date.newInstance(2026, 1, 7);

        insert new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1,
            EG_Project__c = project.Id,
            ExternalID__c = TimeEntryKey.build(card.Id, project.Id, null, workDate)
        );
        EG_Time_Entry__c other = new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1,
            ExternalID__c = TimeEntryKey.build(card.Id, null, null, workDate)
        );
        insert other;

        // Point the second entry at the project already claimed by the first.
        TimeEntryRequest request = new TimeEntryRequest();
        request.timeEntryId = other.Id;
        request.workDate = workDate;
        request.hoursWorked = 2;
        request.projectId = project.Id;

        Test.startTest();
        try {
            new TimeEntryService().createEntry(request);
            System.assert(false, 'Expected an InvalidSelectionException.');
        } catch (TimeEntryService.InvalidSelectionException e) {
            System.assert(
                e.getMessage().contains('already covers'),
                'Unexpected message: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void createEntry_whenTargetedEntryMissing_throwsInvalidSelection() {
        TestDataFactory.newTimeCard(Date.newInstance(2026, 1, 5), Date.newInstance(2026, 1, 11));

        TimeEntryRequest request = new TimeEntryRequest();
        request.timeEntryId = '000000000000000AAA';
        request.workDate = Date.newInstance(2026, 1, 7);
        request.hoursWorked = 1;

        Test.startTest();
        try {
            new TimeEntryService().createEntry(request);
            System.assert(false, 'Expected an InvalidSelectionException.');
        } catch (TimeEntryService.InvalidSelectionException e) {
            System.assert(
                e.getMessage().contains('no longer available'),
                'Unexpected message: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void createEntry_whenTargetedEntryOnAnotherCard_throwsInvalidSelection() {
        EG_Time_Card__c weekOne = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );
        TestDataFactory.newTimeCard(Date.newInstance(2026, 1, 12), Date.newInstance(2026, 1, 18));

        EG_Time_Entry__c weekOneEntry = new EG_Time_Entry__c(
            EG_Time_Card__c = weekOne.Id,
            Date__c = Date.newInstance(2026, 1, 7),
            Hours_Worked__c = 1
        );
        insert weekOneEntry;

        // Same entry, but a date that falls in the following week's card.
        TimeEntryRequest request = new TimeEntryRequest();
        request.timeEntryId = weekOneEntry.Id;
        request.workDate = Date.newInstance(2026, 1, 14);
        request.hoursWorked = 1;

        Test.startTest();
        try {
            new TimeEntryService().createEntry(request);
            System.assert(false, 'Expected an InvalidSelectionException.');
        } catch (TimeEntryService.InvalidSelectionException e) {
            System.assert(
                e.getMessage().contains('different time card'),
                'Unexpected message: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void createEntry_whenTaskNotUnderProject_throwsInvalidSelection() {
        TestDataFactory.newTimeCard(Date.newInstance(2026, 1, 5), Date.newInstance(2026, 1, 11));
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c projectA = TestDataFactory.newProject(opp.Id);
        EG_Project__c projectB = TestDataFactory.newProject(opp.Id);
        EG_Project_Task__c taskUnderA = TestDataFactory.newProjectTask(projectA.Id);

        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.newInstance(2026, 1, 7);
        request.hoursWorked = 1;
        request.projectId = projectB.Id;
        request.projectTaskId = taskUnderA.Id;

        Test.startTest();
        try {
            new TimeEntryService().createEntry(request);
            System.assert(false, 'Expected an InvalidSelectionException.');
        } catch (TimeEntryService.InvalidSelectionException e) {
            System.assert(e.getMessage().contains('task does not belong'), 'Unexpected message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void createEntry_whenProjectNotUnderOpportunity_throwsInvalidSelection() {
        TestDataFactory.newTimeCard(Date.newInstance(2026, 1, 5), Date.newInstance(2026, 1, 11));
        Opportunity oppA = TestDataFactory.newOpportunity();
        Opportunity oppB = TestDataFactory.newOpportunity();
        EG_Project__c projectUnderA = TestDataFactory.newProject(oppA.Id);

        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.newInstance(2026, 1, 7);
        request.hoursWorked = 1;
        request.opportunityId = oppB.Id;
        request.projectId = projectUnderA.Id;

        Test.startTest();
        try {
            new TimeEntryService().createEntry(request);
            System.assert(false, 'Expected an InvalidSelectionException.');
        } catch (TimeEntryService.InvalidSelectionException e) {
            System.assert(e.getMessage().contains('project does not belong'), 'Unexpected message: ' + e.getMessage());
        }
        Test.stopTest();
    }
}