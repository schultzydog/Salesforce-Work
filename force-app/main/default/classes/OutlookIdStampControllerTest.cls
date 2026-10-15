@IsTest
private class OutlookIdStampControllerTest {

    @IsTest
    static void stampsTheMatchedEventFromPageParameters() {
        Datetime startAt = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));
        Event meeting = new Event(
            Subject = 'Stamp Page Meeting',
            Type = 'Meeting',
            StartDateTime = startAt,
            EndDateTime = startAt.addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;
        String uid = '040000008200E00074C5B7101A82E008PAGEUID';

        Test.setCurrentPage(Page.OutlookIdStamp);
        ApexPages.currentPage().getParameters().put('icalUid', uid);
        ApexPages.currentPage().getParameters().put('subject', meeting.Subject);
        ApexPages.currentPage().getParameters().put(
            'start',
            JSON.serialize(startAt).replace('"', '')
        );

        Test.startTest();
        OutlookIdStampController controller = new OutlookIdStampController();
        Test.stopTest();

        System.assertEquals(true, controller.ok, controller.message);
        System.assertEquals(meeting.Id, controller.eventId);
        System.assertEquals(
            uid,
            [SELECT Outlook_iCalUId__c FROM Event WHERE Id = :meeting.Id].Outlook_iCalUId__c
        );
    }

    @IsTest
    static void reportsFailureWhenNothingMatches() {
        Test.setCurrentPage(Page.OutlookIdStamp);

        Test.startTest();
        OutlookIdStampController controller = new OutlookIdStampController();
        Test.stopTest();

        System.assertEquals(false, controller.ok);
        System.assertEquals(null, controller.eventId);
        System.assertEquals(true, String.isNotBlank(controller.message));
    }

    @IsTest
    static void stampsOutlookICalUidWhenBlank() {
        Datetime startAt = Datetime.newInstance(Date.today(), Time.newInstance(11, 0, 0, 0));
        Event meeting = new Event(
            Subject = 'Stamp UID Meeting',
            Type = 'Meeting',
            StartDateTime = startAt,
            EndDateTime = startAt.addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;
        String startIso = JSON.serialize(startAt).replace('"', '');
        String uid = '040000008200E00074C5B7101A82E00800000000TESTUID';

        Test.startTest();
        OutlookIdStampController.StampResult missingUid =
            OutlookIdStampController.stampOutlookId(null, meeting.Subject, startIso);
        OutlookIdStampController.StampResult noMatch =
            OutlookIdStampController.stampOutlookId(uid, 'Not this meeting', startIso);
        OutlookIdStampController.StampResult firstWrite =
            OutlookIdStampController.stampOutlookId(uid, meeting.Subject, startIso);
        OutlookIdStampController.StampResult alreadyThere =
            OutlookIdStampController.stampOutlookId(uid, meeting.Subject, startIso);
        OutlookIdStampController.StampResult differentUid =
            OutlookIdStampController.stampOutlookId(uid + 'X', meeting.Subject, startIso);
        Test.stopTest();

        System.assertEquals(false, missingUid.ok);
        System.assertEquals(false, noMatch.ok);
        System.assertEquals(true, firstWrite.ok);
        System.assertEquals(meeting.Id, firstWrite.eventId);
        System.assertEquals(true, alreadyThere.ok);
        System.assertEquals(false, differentUid.ok);
        System.assertEquals(
            uid,
            [SELECT Outlook_iCalUId__c FROM Event WHERE Id = :meeting.Id].Outlook_iCalUId__c
        );
    }
}
