/**
 * @description Unit tests for TimeCardSelector. Verifies the covering-card query
 * boundaries and null-argument guards without relying on hardcoded org data.
 */
@IsTest
private class TimeCardSelectorTest {
    @IsTest
    static void findCardForDate_returnsCoveringCard() {
        EG_Time_Card__c card = TestDataFactory.newTimeCard(
            Date.newInstance(2026, 1, 5),
            Date.newInstance(2026, 1, 11)
        );

        Test.startTest();
        EG_Time_Card__c found = new TimeCardSelector()
            .findCardForDate(UserInfo.getUserId(), Date.newInstance(2026, 1, 7));
        Test.stopTest();

        System.assertNotEquals(null, found, 'A covering card should be returned.');
        System.assertEquals(card.Id, found.Id, 'The covering card should be the inserted one.');
    }

    @IsTest
    static void findCardForDate_returnsNullOutsideRange() {
        TestDataFactory.newTimeCard(Date.newInstance(2026, 1, 5), Date.newInstance(2026, 1, 11));

        Test.startTest();
        EG_Time_Card__c found = new TimeCardSelector()
            .findCardForDate(UserInfo.getUserId(), Date.newInstance(2026, 2, 1));
        Test.stopTest();

        System.assertEquals(null, found, 'No card should be returned for a date outside any range.');
    }

    @IsTest
    static void findCardForDate_returnsNullOnNullArguments() {
        TimeCardSelector selector = new TimeCardSelector();
        System.assertEquals(null, selector.findCardForDate(null, Date.today()), 'Null owner should yield null.');
        System.assertEquals(null, selector.findCardForDate(UserInfo.getUserId(), null), 'Null date should yield null.');
    }
}