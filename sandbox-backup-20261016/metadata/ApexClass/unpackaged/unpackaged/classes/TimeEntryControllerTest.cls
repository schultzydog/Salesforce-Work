/**
 * @description Unit tests for TimeEntryController. Verifies delegation to the
 * service on the happy path and that service failures surface as
 * AuraHandledExceptions for the LWC.
 */
@IsTest
private class TimeEntryControllerTest {
    @IsTest
    static void createTimeEntry_happyPath_returnsResult() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );

        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.newInstance(2026, 1, 7);
        request.hoursWorked = 3;
        request.notes = 'Design review';

        Test.startTest();
        TimeEntryService.TimeEntryResult result = TimeEntryController.createTimeEntry(request);
        Test.stopTest();

        System.assertNotEquals(null, result.timeEntryId, 'An entry Id should be returned.');
        System.assertEquals(card.Id, result.timeCardId, 'The result should reference the covering card.');
    }

    @IsTest
    static void createTimeEntry_whenNoCard_throwsAuraHandled() {
        TimeEntryRequest request = new TimeEntryRequest();
        request.workDate = Date.newInstance(2026, 4, 1);
        request.hoursWorked = 2;

        Test.startTest();
        try {
            TimeEntryController.createTimeEntry(request);
            System.assert(false, 'Expected an AuraHandledException.');
        } catch (AuraHandledException e) {
            System.assert(true, 'Service failure surfaced as AuraHandledException.');
        }
        Test.stopTest();
    }

    @IsTest
    static void getEntriesForDate_returnsExistingEntries() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );
        Date workDate = Date.newInstance(2026, 1, 7);
        insert new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1.5
        );

        Test.startTest();
        List<TimeEntrySummary> summaries = TimeEntryController.getEntriesForDate(workDate);
        Test.stopTest();

        System.assertEquals(1, summaries.size(), 'The existing entry should be returned.');
        System.assertEquals(1.5, summaries[0].hoursWorked, 'Hours should be included.');
    }
}