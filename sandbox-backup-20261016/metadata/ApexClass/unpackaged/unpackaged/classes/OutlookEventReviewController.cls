/**
 * Backs the Outlook Event Review table: the running user's owned Events,
 * working-location updates, and the time entry each row writes. A row only
 * ever reports the time entry its Event is actually linked to; projects and
 * entries are never inferred.
 *
 * Find and save use Source_Event_Id__c plus the running user's time-card
 * ownership (one entry per event per owner). ExternalID__c is stamped as
 * card:project:task:date:eventId:userEmail and is not used to look rows up.
 */
public with sharing class OutlookEventReviewController {

    public class RelatedPerson {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String url;
    }

    public class ActivityRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String subject;
        @AuraEnabled public Datetime activityDate;
        @AuraEnabled public Long startMillis;
        @AuraEnabled public String dayName;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public List<RelatedPerson> attendees;
        @AuraEnabled public Decimal hours;
        @AuraEnabled public Date workDate;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String workingLocation;
        @AuraEnabled public Boolean hasTimeEntry;
        @AuraEnabled public Id timeEntryId;
        @AuraEnabled public Id suggestedProjectId;
        @AuraEnabled public String suggestedProjectName;
        @AuraEnabled public Id projectTaskId;
        @AuraEnabled public String projectTaskName;
        @AuraEnabled public String timeCategory;
        @AuraEnabled public Boolean internal;
    }

    /**
     * What the Outlook panel gets back for an inbox item: the Salesforce Event
     * it belongs to, that event's Account, and the time entry the event is
     * linked to. Project, task, hours, and notes are only ever read off that
     * linked entry, never inferred.
     */
    public class MatchingEvent {
        @AuraEnabled public Id id;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Id suggestedProjectId;
        @AuraEnabled public String suggestedProjectName;
        @AuraEnabled public Id projectTaskId;
        @AuraEnabled public String projectTaskName;
        @AuraEnabled public Id timeEntryId;
        @AuraEnabled public Decimal hours;
        @AuraEnabled public String notes;
    }

    @AuraEnabled
    public static List<ActivityRow> getMyActivities(Date startDate, Date endDate) {
        Date fromDate = startDate == null ? Date.today().addDays(-180) : startDate;
        Date toDate = endDate == null ? Date.today().addDays(90) : endDate;
        Datetime startBound = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
        Datetime endBound = Datetime.newInstance(toDate, Time.newInstance(23, 59, 59, 0));
        Id ownerId = UserInfo.getUserId();

        List<Event> events = [
            SELECT Id, Subject, StartDateTime, DurationInMinutes, Location,
                   WhatId, What.Name, AccountId, Account.Name,
                   WhoId, Who.Name,
                   ClientGuid, Type, Activity_Type__c
            FROM Event
            WHERE OwnerId = :ownerId
            AND IsRecurrence2 = false
            AND StartDateTime >= :startBound
            AND StartDateTime <= :endBound
            AND (ClientGuid != null OR Type = 'Meeting' OR Activity_Type__c = 'Meeting')
            ORDER BY StartDateTime DESC
            LIMIT 500
        ];

        Set<Date> workDates = new Set<Date>();
        Set<String> eventKeys = new Set<String>();
        for (Event record : events) {
            if (record.StartDateTime != null) {
                workDates.add(record.StartDateTime.date());
            }
            eventKeys.add(String.valueOf(record.Id));
        }

        Map<Date, EG_Time_Card__c> cardsByDate = cardsByDate(ownerId, workDates);
        Map<String, EG_Time_Entry__c> entriesByEvent = entriesByEvent(eventKeys);

        List<ActivityRow> rows = new List<ActivityRow>();
        for (Event record : events) {
            ActivityRow row = new ActivityRow();
            row.id = record.Id;
            row.subject = record.Subject;
            row.activityDate = record.StartDateTime;
            row.startMillis = record.StartDateTime == null
                ? null
                : record.StartDateTime.getTime();
            row.dayName = record.StartDateTime == null
                ? null
                : record.StartDateTime.format('EEEE');
            row.hours = record.DurationInMinutes == null
                ? null
                : Decimal.valueOf(record.DurationInMinutes) / 60;
            row.workDate = record.StartDateTime == null ? null : record.StartDateTime.date();
            row.recordUrl = '/' + record.Id;
            row.accountName = record.Account == null ? null : record.Account.Name;
            Id linkedAccountId = record.AccountId;
            if (String.isBlank(row.accountName) && record.WhatId != null
                && record.WhatId.getSObjectType() == Account.SObjectType) {
                row.accountName = record.What.Name;
                linkedAccountId = record.WhatId;
            }
            row.accountId = linkedAccountId;
            row.accountUrl = linkedAccountId == null ? null : '/' + linkedAccountId;
            row.internal = false;

            EG_Time_Card__c card = cardsByDate.get(row.workDate);
            row.workingLocation = locationFor(card, row.workDate);

            // Project, task, and hours are read back only from the entry this
            // event is linked to. Nothing is inferred from the event's related
            // record or from other entries on the same day.
            EG_Time_Entry__c matched = entriesByEvent.get(String.valueOf(record.Id));
            row.hasTimeEntry = matched != null;
            if (matched != null) {
                row.timeEntryId = matched.Id;
                if (matched.Hours_Worked__c != null) {
                    row.hours = matched.Hours_Worked__c;
                }
                if (matched.EG_Project__c != null) {
                    row.suggestedProjectId = matched.EG_Project__c;
                }
                row.projectTaskId = matched.EG_Project_Task__c;
                row.timeCategory = matched.Time_Category__c;
                row.internal = matched.Internal__c == true;
            }
            rows.add(row);
        }
        applyLookupNames(rows);
        applyAttendees(rows, events);
        return rows;
    }

    /**
     * Collects the Contacts and Leads already associated with each Event
     * through the standard activity relationships: the primary WhoId plus the
     * EventRelation invitees. WhatId relations are skipped because those are
     * records, not people.
     */
    private static void applyAttendees(List<ActivityRow> rows, List<Event> events) {
        Map<Id, List<RelatedPerson>> peopleByEvent = new Map<Id, List<RelatedPerson>>();
        Map<Id, Set<Id>> seenByEvent = new Map<Id, Set<Id>>();
        for (ActivityRow row : rows) {
            row.attendees = new List<RelatedPerson>();
            peopleByEvent.put(row.id, row.attendees);
            seenByEvent.put(row.id, new Set<Id>());
        }
        if (peopleByEvent.isEmpty()) {
            return;
        }
        for (Event record : events) {
            addAttendee(
                peopleByEvent,
                seenByEvent,
                record.Id,
                record.WhoId,
                record.Who == null ? null : record.Who.Name
            );
        }
        for (EventRelation relation : [
            SELECT EventId, RelationId, Relation.Name
            FROM EventRelation
            WHERE EventId IN :peopleByEvent.keySet()
            AND IsWhat = false
        ]) {
            addAttendee(
                peopleByEvent,
                seenByEvent,
                relation.EventId,
                relation.RelationId,
                relation.Relation == null ? null : relation.Relation.Name
            );
        }
    }

    private static void addAttendee(
        Map<Id, List<RelatedPerson>> peopleByEvent,
        Map<Id, Set<Id>> seenByEvent,
        Id eventId,
        Id personId,
        String personName
    ) {
        if (eventId == null || personId == null || !peopleByEvent.containsKey(eventId)) {
            return;
        }
        Schema.SObjectType personType = personId.getSObjectType();
        if (personType != Contact.SObjectType && personType != Lead.SObjectType) {
            return;
        }
        Set<Id> seen = seenByEvent.get(eventId);
        if (seen.contains(personId)) {
            return;
        }
        seen.add(personId);
        RelatedPerson person = new RelatedPerson();
        person.id = personId;
        person.name = String.isBlank(personName) ? String.valueOf(personId) : personName;
        person.url = '/' + personId;
        peopleByEvent.get(eventId).add(person);
    }

    /**
     * Repoints the Event at a different Account. AccountId is derived and not
     * writable, so the association is stored on WhatId, which is the same place
     * getMyActivities already falls back to when reading the account.
     */
    @AuraEnabled
    public static void updateEventAccount(Id eventId, Id accountId) {
        if (eventId == null || eventId.getSObjectType() != Event.SObjectType) {
            throw new AuraHandledException('An event is required.');
        }
        if (accountId != null && accountId.getSObjectType() != Account.SObjectType) {
            throw new AuraHandledException('Choose an account.');
        }
        update new Event(Id = eventId, WhatId = accountId);
    }

    private static void applyLookupNames(List<ActivityRow> rows) {
        Set<Id> projectIds = new Set<Id>();
        Set<Id> taskIds = new Set<Id>();
        for (ActivityRow row : rows) {
            if (row.suggestedProjectId != null) {
                projectIds.add(row.suggestedProjectId);
            }
            if (row.projectTaskId != null) {
                taskIds.add(row.projectTaskId);
            }
        }
        Map<Id, EG_Project__c> projects = projectIds.isEmpty()
            ? new Map<Id, EG_Project__c>()
            : new Map<Id, EG_Project__c>([SELECT Id, Name FROM EG_Project__c WHERE Id IN :projectIds]);
        Map<Id, EG_Project_Task__c> tasks = taskIds.isEmpty()
            ? new Map<Id, EG_Project_Task__c>()
            : new Map<Id, EG_Project_Task__c>([SELECT Id, Name FROM EG_Project_Task__c WHERE Id IN :taskIds]);
        for (ActivityRow row : rows) {
            EG_Project__c project = projects.get(row.suggestedProjectId);
            row.suggestedProjectName = project == null ? null : project.Name;
            EG_Project_Task__c task = tasks.get(row.projectTaskId);
            row.projectTaskName = task == null ? null : task.Name;
        }
    }

    @AuraEnabled
    public static MatchingEvent findMatchingEvent(String subject, String startIso) {
        Datetime startAt = parseIso(startIso);
        if (startAt == null) {
            return null;
        }
        Datetime low = startAt.addMinutes(-2);
        Datetime high = startAt.addMinutes(2);
        Id ownerId = UserInfo.getUserId();
        String eventSubject = String.isBlank(subject) ? null : subject;

        List<Event> events;
        if (eventSubject != null) {
            events = [
                SELECT Id, Subject, StartDateTime, WhatId, What.Name, AccountId, Account.Name
                FROM Event
                WHERE OwnerId = :ownerId
                AND IsRecurrence2 = false
                AND StartDateTime >= :low
                AND StartDateTime <= :high
                AND Subject = :eventSubject
                AND (ClientGuid != null OR Type = 'Meeting' OR Activity_Type__c = 'Meeting')
                ORDER BY LastModifiedDate DESC
                LIMIT 1
            ];
        } else {
            events = [
                SELECT Id, Subject, StartDateTime, WhatId, What.Name, AccountId, Account.Name
                FROM Event
                WHERE OwnerId = :ownerId
                AND IsRecurrence2 = false
                AND StartDateTime >= :low
                AND StartDateTime <= :high
                AND (ClientGuid != null OR Type = 'Meeting' OR Activity_Type__c = 'Meeting')
                ORDER BY LastModifiedDate DESC
                LIMIT 2
            ];
            if (events.size() != 1) {
                return null;
            }
        }
        if (events.isEmpty()) {
            return null;
        }
        return toMatchingEvent(events[0]);
    }

    @AuraEnabled
    public static void linkEventTimeEntry(Id eventId, Id timeEntryId) {
        if (eventId == null || eventId.getSObjectType() != Event.SObjectType) {
            throw new AuraHandledException('An event is required.');
        }
        if (timeEntryId == null || timeEntryId.getSObjectType() != EG_Time_Entry__c.SObjectType) {
            throw new AuraHandledException('A time entry is required.');
        }
        String eventKey = String.valueOf(eventId);
        List<EG_Time_Entry__c> entries = [
            SELECT Id, Source_Event_Id__c
            FROM EG_Time_Entry__c
            WHERE Id = :timeEntryId
            AND EG_Time_Card__r.OwnerId = :UserInfo.getUserId()
            LIMIT 1
        ];
        if (entries.isEmpty()) {
            throw new AuraHandledException(
                'That time entry sits on another user\'s time card.'
            );
        }
        if (entries[0].Source_Event_Id__c != eventKey) {
            update new EG_Time_Entry__c(
                Id = entries[0].Id,
                Source_Event_Id__c = eventKey
            );
        }
        releaseOtherEntries(eventId, entries[0].Id);
    }

    /**
     * The entries claiming these events, keyed by event id. Scoped to the
     * running user's own time cards so a shared event never surfaces someone
     * else's time on this user's row.
     */
    private static Map<String, EG_Time_Entry__c> entriesByEvent(Set<String> eventKeys) {
        Map<String, EG_Time_Entry__c> byEvent = new Map<String, EG_Time_Entry__c>();
        if (eventKeys.isEmpty()) {
            return byEvent;
        }
        for (EG_Time_Entry__c entry : [
            SELECT Id, Source_Event_Id__c, EG_Time_Card__c, EG_Project__c,
                   EG_Project_Task__c, Date__c, Hours_Worked__c, Notes__c,
                   Time_Category__c, Internal__c
            FROM EG_Time_Entry__c
            WHERE Source_Event_Id__c IN :eventKeys
            AND EG_Time_Card__r.OwnerId = :UserInfo.getUserId()
            ORDER BY CreatedDate
        ]) {
            // First one wins: the field is plain text, so nothing at the
            // database level stops a second row from claiming the same event.
            if (!byEvent.containsKey(entry.Source_Event_Id__c)) {
                byEvent.put(entry.Source_Event_Id__c, entry);
            }
        }
        return byEvent;
    }

    private static EG_Time_Entry__c entryForEvent(Id eventId) {
        return entriesByEvent(new Set<String>{ String.valueOf(eventId) })
            .get(String.valueOf(eventId));
    }

    /**
     * One owner, one entry per event. Source_Event_Id__c is text, so if a
     * second row for this user somehow claims the same event, clear it. Other
     * owners' entries for the same event are left alone (owner filter).
     */
    private static void releaseOtherEntries(Id eventId, Id keepEntryId) {
        List<EG_Time_Entry__c> stale = [
            SELECT Id
            FROM EG_Time_Entry__c
            WHERE Source_Event_Id__c = :String.valueOf(eventId)
            AND Id != :keepEntryId
            AND EG_Time_Card__r.OwnerId = :UserInfo.getUserId()
        ];
        if (stale.isEmpty()) {
            return;
        }
        for (EG_Time_Entry__c entry : stale) {
            entry.Source_Event_Id__c = null;
        }
        update stale;
    }

    private static MatchingEvent toMatchingEvent(Event record) {
        MatchingEvent match = new MatchingEvent();
        match.id = record.Id;
        match.accountName = record.Account == null ? null : record.Account.Name;
        Id linkedAccountId = record.AccountId;
        if (String.isBlank(match.accountName) && record.WhatId != null
            && record.WhatId.getSObjectType() == Account.SObjectType) {
            match.accountName = record.What.Name;
            linkedAccountId = record.WhatId;
        }
        match.accountId = linkedAccountId;

        // Only the entry this event is linked to can fill the panel's project,
        // task, hours, and notes. Nothing is inferred from WhatId, a related
        // opportunity, or the account.
        EG_Time_Entry__c linked = entryForEvent(record.Id);
        if (linked != null) {
            match.timeEntryId = linked.Id;
            match.suggestedProjectId = linked.EG_Project__c;
            match.projectTaskId = linked.EG_Project_Task__c;
            match.hours = linked.Hours_Worked__c;
            match.notes = linked.Notes__c;
        }
        ActivityRow names = new ActivityRow();
        names.suggestedProjectId = match.suggestedProjectId;
        names.projectTaskId = match.projectTaskId;
        applyLookupNames(new List<ActivityRow>{ names });
        match.suggestedProjectName = names.suggestedProjectName;
        match.projectTaskName = names.projectTaskName;
        return match;
    }

    private static Datetime parseIso(String startIso) {
        if (String.isBlank(startIso)) {
            return null;
        }
        try {
            String jsonValue = startIso.trim();
            if (!jsonValue.startsWith('"')) {
                jsonValue = '"' + jsonValue + '"';
            }
            return (Datetime) JSON.deserialize(jsonValue, Datetime.class);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Trash on the Event Review table: remove the running user's linked time
     * entry (if any), then the Event. One transaction so a failed Event delete
     * rolls the entry delete back.
     */
    @AuraEnabled
    public static void deleteEvent(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('A record is required.');
        }
        String prefix = String.valueOf(recordId).substring(0, 3);
        if (prefix != Event.SObjectType.getDescribe().getKeyPrefix()) {
            throw new AuraHandledException('Only events can be deleted.');
        }
        delete [
            SELECT Id
            FROM EG_Time_Entry__c
            WHERE Source_Event_Id__c = :String.valueOf(recordId)
            AND EG_Time_Card__r.OwnerId = :UserInfo.getUserId()
        ];
        delete new Event(Id = recordId);
    }

    @AuraEnabled
    public static Id saveTimeEntry(
        Id eventId,
        Date workDate,
        Decimal hoursWorked,
        Id projectId,
        Id projectTaskId
    ) {
        if (eventId == null || eventId.getSObjectType() != Event.SObjectType) {
            throw new AuraHandledException('An event is required.');
        }
        if (workDate == null) {
            throw new AuraHandledException('A date is required.');
        }
        if (hoursWorked == null || hoursWorked <= 0) {
            throw new AuraHandledException('Hours must be greater than zero.');
        }
        if (projectId == null) {
            throw new AuraHandledException('Choose a project before logging hours.');
        }
        if (projectTaskId != null) {
            List<EG_Project_Task__c> tasks = [
                SELECT Id
                FROM EG_Project_Task__c
                WHERE Id = :projectTaskId
                AND EG_Project__c = :projectId
                LIMIT 1
            ];
            if (tasks.isEmpty()) {
                throw new AuraHandledException(
                    'That task does not belong to the selected project.'
                );
            }
        }

        Id timeCardId = findTimeCardId(workDate);
        String externalId =
            externalIdFor(timeCardId, projectId, projectTaskId, workDate, eventId);

        // Match on the event link + owner (entryForEvent), not by ExternalID.
        // ExternalID is a uniqueness tag only.
        EG_Time_Entry__c existing = entryForEvent(eventId);
        if (existing != null) {
            existing.EG_Time_Card__c = timeCardId;
            existing.Date__c = workDate;
            existing.Hours_Worked__c = hoursWorked;
            existing.EG_Project__c = projectId;
            existing.EG_Project_Task__c = projectTaskId;
            existing.ExternalID__c = externalId;
            update existing;
            releaseOtherEntries(eventId, existing.Id);
            return existing.Id;
        }

        EG_Time_Entry__c entry = new EG_Time_Entry__c(
            EG_Time_Card__c = timeCardId,
            Date__c = workDate,
            Hours_Worked__c = hoursWorked,
            EG_Project__c = projectId,
            EG_Project_Task__c = projectTaskId,
            Source_Event_Id__c = String.valueOf(eventId),
            ExternalID__c = externalId,
            Time_Entry_Source__c = 'Event_Review_Page'
        );
        insert entry;
        releaseOtherEntries(eventId, entry.Id);
        return entry.Id;
    }

    /**
     * Deletes the entry the event is linked to. Changing or clearing the
     * account or project leaves that entry logging work the row no longer
     * claims, so it goes with the change. Scoped to the running user's own
     * time cards so a shared event can't delete someone else's time.
     */
    @AuraEnabled
    public static void deleteTimeEntryForEvent(Id eventId) {
        if (eventId == null || eventId.getSObjectType() != Event.SObjectType) {
            throw new AuraHandledException('An event is required.');
        }
        delete [
            SELECT Id
            FROM EG_Time_Entry__c
            WHERE Source_Event_Id__c = :String.valueOf(eventId)
            AND EG_Time_Card__r.OwnerId = :UserInfo.getUserId()
        ];
    }

    /**
     * Retags the linked entry with a different task. An entry is valid with or
     * without a task, so the record is updated in place and keeps its hours,
     * source, and automation flag. Found by Source_Event_Id__c; saved by Id.
     */
    @AuraEnabled
    public static Id updateTimeEntryTask(Id eventId, Id projectTaskId) {
        if (eventId == null || eventId.getSObjectType() != Event.SObjectType) {
            throw new AuraHandledException('An event is required.');
        }
        EG_Time_Entry__c entry = entryForEvent(eventId);
        if (entry == null) {
            return null;
        }
        if (projectTaskId != null) {
            List<EG_Project_Task__c> tasks = [
                SELECT Id
                FROM EG_Project_Task__c
                WHERE Id = :projectTaskId
                AND EG_Project__c = :entry.EG_Project__c
                LIMIT 1
            ];
            if (tasks.isEmpty()) {
                throw new AuraHandledException(
                    'That task does not belong to the selected project.'
                );
            }
        }
        entry.EG_Project_Task__c = projectTaskId;
        update entry;
        return entry.Id;
    }

    /**
     * Returns at most two rows so the caller can tell "exactly one active
     * project" from "more than one" without a second query.
     */
    @AuraEnabled
    public static List<EG_Project__c> activeProjectsForAccount(Id accountId) {
        if (accountId == null || accountId.getSObjectType() != Account.SObjectType) {
            return new List<EG_Project__c>();
        }
        return [
            SELECT Id, Name
            FROM EG_Project__c
            WHERE Account__c = :accountId
            AND Status__c = 'Active'
            ORDER BY Name
            LIMIT 2
        ];
    }

    private static Id findTimeCardId(Date workDate) {
        List<EG_Time_Card__c> cards = [
            SELECT Id
            FROM EG_Time_Card__c
            WHERE OwnerId = :UserInfo.getUserId()
            AND Start_Date__c <= :workDate
            AND End_Date__c >= :workDate
            ORDER BY Start_Date__c DESC
            LIMIT 1
        ];
        if (cards.isEmpty()) {
            throw new AuraHandledException(
                'No time card was found for the week of ' +
                String.valueOf(workDate) +
                '. Create your weekly time card before logging time.'
            );
        }
        return cards[0].Id;
    }

    /**
     * ExternalID__c tag: card:project:task:date:eventId:userEmail.
     * Find/save use Source_Event_Id__c + owner, not this string.
     */
    @TestVisible
    private static String externalIdFor(
        Id timeCardId,
        Id projectId,
        Id projectTaskId,
        Date workDate,
        Id eventId
    ) {
        return TimeEntryKey.build(timeCardId, projectId, projectTaskId, workDate)
            + ':'
            + eventId
            + ':'
            + UserInfo.getUserEmail();
    }

    /** Legacy four-part tag for older tests that do not involve an event. */
    @TestVisible
    private static String externalIdFor(
        Id timeCardId,
        Id projectId,
        Id projectTaskId,
        Date workDate
    ) {
        return TimeEntryKey.build(timeCardId, projectId, projectTaskId, workDate);
    }
/*
    @AuraEnabled
    public static void setWorkingLocation(Date workDate, String locationValue) {
        if (workDate == null) {
            throw new AuraHandledException('A date is required.');
        }
        String fieldName = locationFieldFor(workDate);
        if (fieldName == null) {
            return;
        }
        List<EG_Time_Card__c> cards = [
            SELECT Id
            FROM EG_Time_Card__c
            WHERE OwnerId = :UserInfo.getUserId()
            AND Start_Date__c <= :workDate
            AND End_Date__c >= :workDate
            ORDER BY Start_Date__c DESC
            LIMIT 1
        ];
        if (cards.isEmpty()) {
            throw new AuraHandledException(
                'No time card was found for the week of ' +
                String.valueOf(workDate) +
                '. Create your weekly time card before logging a location.'
            );
        }
        EG_Time_Card__c updateCard = new EG_Time_Card__c(Id = cards[0].Id);
        updateCard.put(fieldName, locationValue);
        update updateCard;
    }
*/
    private static Map<Date, EG_Time_Card__c> cardsByDate(Id ownerId, Set<Date> workDates) {
        Map<Date, EG_Time_Card__c> byDate = new Map<Date, EG_Time_Card__c>();
        if (workDates.isEmpty()) {
            return byDate;
        }
        Date minDate;
        Date maxDate;
        for (Date workDate : workDates) {
            minDate = minDate == null || workDate < minDate ? workDate : minDate;
            maxDate = maxDate == null || workDate > maxDate ? workDate : maxDate;
        }
        List<EG_Time_Card__c> cards = [
            SELECT Id, Start_Date__c, End_Date__c,
                   Location_Monday__c, Location_Tuesday__c, Location_Wednesday__c,
                   Location_Thursday__c, Location_Friday__c
            FROM EG_Time_Card__c
            WHERE OwnerId = :ownerId
            AND Start_Date__c <= :maxDate
            AND End_Date__c >= :minDate
        ];
        for (Date workDate : workDates) {
            for (EG_Time_Card__c card : cards) {
                if (card.Start_Date__c <= workDate && card.End_Date__c >= workDate) {
                    byDate.put(workDate, card);
                    break;
                }
            }
        }
        return byDate;
    }

    private static String locationFor(EG_Time_Card__c card, Date workDate) {
        if (card == null || workDate == null) {
            return null;
        }
        String fieldName = locationFieldFor(workDate);
        if (fieldName == null) {
            return null;
        }
        return (String) card.get(fieldName);
    }

    private static String locationFieldFor(Date workDate) {
        String dayName = Datetime.newInstance(workDate, Time.newInstance(12, 0, 0, 0)).format('EEEE');
        if (dayName == 'Monday') {
            return 'Location_Monday__c';
        }
        if (dayName == 'Tuesday') {
            return 'Location_Tuesday__c';
        }
        if (dayName == 'Wednesday') {
            return 'Location_Wednesday__c';
        }
        if (dayName == 'Thursday') {
            return 'Location_Thursday__c';
        }
        if (dayName == 'Friday') {
            return 'Location_Friday__c';
        }
        return null;
    }
}