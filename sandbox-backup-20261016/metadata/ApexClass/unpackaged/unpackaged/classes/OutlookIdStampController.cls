/**
 * Backs the Outlook ID Dump VF page. Owns every reference to
 * Activity.Outlook_iCalUId__c so Outlook Event Review can deploy without that
 * field. Matching still reuses OutlookEventReviewController.findMatchingEvent.
 */
public with sharing class OutlookIdStampController {
    public Boolean ok { get; private set; }
    public String message { get; private set; }
    public Id eventId { get; private set; }

    public class StampResult {
        @AuraEnabled public Boolean ok;
        @AuraEnabled public String message;
        @AuraEnabled public Id eventId;
    }

    public OutlookIdStampController() {
        ok = false;
        String iCalUId = ApexPages.currentPage().getParameters().get('icalUid');
        String subject = ApexPages.currentPage().getParameters().get('subject');
        String startIso = ApexPages.currentPage().getParameters().get('start');
        StampResult stamped = stampOutlookId(iCalUId, subject, startIso);
        ok = stamped.ok == true;
        message = stamped.message;
        eventId = stamped.eventId;
    }

    public static StampResult stampOutlookId(String iCalUId, String subject, String startIso) {
        StampResult result = new StampResult();
        result.ok = false;
        if (String.isBlank(iCalUId)) {
            result.message =
                'Outlook did not return an iCal UID. Save the appointment, then Refresh IDs.';
            return result;
        }
        String uid = iCalUId.trim();
        if (uid.length() > 255) {
            result.message = 'The Outlook iCal UID is longer than 255 characters.';
            return result;
        }

        Id ownerId = UserInfo.getUserId();
        List<Event> byUid = [
            SELECT Id, Subject, Outlook_iCalUId__c
            FROM Event
            WHERE OwnerId = :ownerId
            AND Outlook_iCalUId__c = :uid
            LIMIT 1
        ];
        if (!byUid.isEmpty()) {
            result.ok = true;
            result.eventId = byUid[0].Id;
            result.message =
                'Already stored on ' + byUid[0].Id + ' (' + byUid[0].Subject + ').';
            return result;
        }

        OutlookEventReviewController.MatchingEvent match =
            OutlookEventReviewController.findMatchingEvent(subject, startIso);
        if (match == null) {
            result.message =
                'No matching Salesforce Event for this Outlook item (same owner, subject, and start). The id was not written.';
            return result;
        }

        Event record = [
            SELECT Id, Subject, Outlook_iCalUId__c
            FROM Event
            WHERE Id = :match.id
            LIMIT 1
        ];
        if (String.isNotBlank(record.Outlook_iCalUId__c)) {
            if (record.Outlook_iCalUId__c == uid) {
                result.ok = true;
                result.eventId = record.Id;
                result.message =
                    'Already stored on ' + record.Id + ' (' + record.Subject + ').';
                return result;
            }
            result.message =
                'That Salesforce Event already has a different Outlook iCal UID. It was not overwritten.';
            return result;
        }

        record.Outlook_iCalUId__c = uid;
        update record;
        result.ok = true;
        result.eventId = record.Id;
        result.message = 'Wrote Outlook iCal UID onto ' + record.Id + ' (' + record.Subject + ').';
        return result;
    }
}