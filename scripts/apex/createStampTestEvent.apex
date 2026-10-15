// Creates a clean, unstamped meeting so the Visualforce page can be tested in a
// browser without Outlook. Prints the URL to paste.
Datetime startAt = Datetime.newInstance(Date.today(), Time.newInstance(16, 30, 0, 0));
Event meeting = new Event(
    Subject = 'Browser Stamp Test',
    Type = 'Meeting',
    StartDateTime = startAt,
    EndDateTime = startAt.addHours(1),
    OwnerId = UserInfo.getUserId()
);
insert meeting;

String startIso = JSON.serialize(startAt).replace('"', '');
System.debug('EVENT ' + meeting.Id);
System.debug('URL /apex/OutlookIdStamp?icalUid=BROWSER-TEST-UID-123'
    + '&subject=' + EncodingUtil.urlEncode('Browser Stamp Test', 'UTF-8')
    + '&start=' + EncodingUtil.urlEncode(startIso, 'UTF-8'));
