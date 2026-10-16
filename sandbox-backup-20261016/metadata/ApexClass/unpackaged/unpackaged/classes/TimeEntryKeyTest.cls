/**
 * @description Locks the ExternalID__c format contract shared with egEventLogic.
 *
 * These assertions look pedantic on purpose: the date must serialize with a
 * trailing " 00:00:00" and null lookups must render as "null". Changing either
 * would silently stop the panel from matching entries the automation created.
 */
@IsTest
private class TimeEntryKeyTest {
    private static final Id CARD_ID = '000000000000000AAA';
    private static final Id PROJECT_ID = '000000000000001AAA';
    private static final Id TASK_ID = '000000000000002AAA';

    @IsTest
    static void build_withAllParts_matchesLegacyFormat() {
        String key = TimeEntryKey.build(
            CARD_ID,
            PROJECT_ID,
            TASK_ID,
            Date.newInstance(2026, 7, 24)
        );

        System.assertEquals(
            '000000000000000AAA:000000000000001AAA:000000000000002AAA:2026-07-24 00:00:00',
            key,
            'Key must match the string egEventLogic writes.'
        );
    }

    @IsTest
    static void build_withNullTask_rendersNullLiteral() {
        String key = TimeEntryKey.build(
            CARD_ID,
            PROJECT_ID,
            null,
            Date.newInstance(2026, 7, 24)
        );

        System.assertEquals(
            '000000000000000AAA:000000000000001AAA:null:2026-07-24 00:00:00',
            key,
            'A missing task must render as the literal "null".'
        );
    }
}