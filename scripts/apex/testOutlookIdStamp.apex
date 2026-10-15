// Proves the stamp path end-to-end: create an owned meeting, stamp it the way
// the Outlook add-in would, then confirm the id is written and not overwritten.
Datetime startAt = Datetime.newInstance(Date.today(), Time.newInstance(14, 0, 0, 0));
Event meeting = new Event(
    Subject = 'iCal UID Stamp Test',
    Type = 'Meeting',
    StartDateTime = startAt,
    EndDateTime = startAt.addHours(1),
    OwnerId = UserInfo.getUserId()
);
insert meeting;
System.debug('Created event: ' + meeting.Id);

String startIso = JSON.serialize(startAt).replace('"', '');
String uid = '040000008200E00074C5B7101A82E00800000000REALTEST';

OutlookEventReviewController.StampResult first =
    OutlookEventReviewController.stampOutlookId(uid, 'iCal UID Stamp Test', startIso);
System.debug('FIRST ok=' + first.ok + ' event=' + first.eventId + ' msg=' + first.message);

OutlookEventReviewController.StampResult again =
    OutlookEventReviewController.stampOutlookId(uid, 'iCal UID Stamp Test', startIso);
System.debug('REPEAT ok=' + again.ok + ' msg=' + again.message);

OutlookEventReviewController.StampResult other =
    OutlookEventReviewController.stampOutlookId('DIFFERENT-UID', 'iCal UID Stamp Test', startIso);
System.debug('DIFFERENT ok=' + other.ok + ' msg=' + other.message);

Event stored = [SELECT Id, Subject, Outlook_iCalUId__c FROM Event WHERE Id = :meeting.Id];
System.debug('STORED uid=' + stored.Outlook_iCalUId__c);
