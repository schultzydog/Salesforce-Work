/**
 * @description Service layer that owns the business logic for creating time
 * entries from Outlook events. Controllers (LWC, and future Flow/API callers)
 * stay thin and delegate here so the logic has a single, testable home.
 *
 * Extensibility notes:
 *  - createEntry accepts a DTO, so Phase 2 (Opportunity/Project/Task) adds
 *    fields without changing the signature.
 *  - The returned TimeEntryResult can later carry AI suggestions + confidence
 *    (Phase 3/4) without breaking existing callers.
 */
public with sharing class TimeEntryService {
    /**
     * Selector dependencies. Exposed as @TestVisible so unit tests can inject
     * stubs and avoid creating data for pure logic tests.
     */
    @TestVisible
    private TimeCardSelector timeCardSelector = new TimeCardSelector();
    @TestVisible
    private ProjectSelector projectSelector = new ProjectSelector();
    @TestVisible
    private ProjectTaskSelector projectTaskSelector = new ProjectTaskSelector();
    @TestVisible
    private TimeEntrySelector timeEntrySelector = new TimeEntrySelector();

    /** Thrown when no time card covers the requested work date. */
    public class TimeCardNotFoundException extends Exception {}

    /** Thrown when the selected Opportunity/Project/Task don't relate correctly. */
    public class InvalidSelectionException extends Exception {}

    /** Outcome of a create operation, returned to the UI. */
    public class TimeEntryResult {
        @AuraEnabled
        public Id timeEntryId { get; set; }
        @AuraEnabled
        public Id timeCardId { get; set; }
        /** True when an existing entry was updated rather than a new one created. */
        @AuraEnabled
        public Boolean wasUpdated { get; set; }

        public TimeEntryResult(Id timeEntryId, Id timeCardId, Boolean wasUpdated) {
            this.timeEntryId = timeEntryId;
            this.timeCardId = timeCardId;
            this.wasUpdated = wasUpdated;
        }
    }

    /**
     * @description Creates or updates a single EG_Time_Entry__c from a reviewed
     * request. Resolves the owning weekly time card by date, validates its
     * existence, then matches on the canonical external id: an existing entry
     * for that key is updated, otherwise a new one is inserted. All DML runs in
     * user mode (enforcing CRUD/FLS).
     * @param request The user-reviewed values from the Outlook panel.
     * @return TimeEntryResult with the entry Id, time card Id, and whether an
     * existing entry was updated.
     * @throws IllegalArgumentException when the request is missing required data.
     * @throws TimeCardNotFoundException when no card covers the work date.
     */
    public TimeEntryResult createEntry(TimeEntryRequest request) {
        validateRequest(request);
        validateAndResolveSelections(request);

        Id ownerId = UserInfo.getUserId();
        EG_Time_Card__c card = timeCardSelector.findCardForDate(ownerId, request.workDate);
        if (card == null) {
            throw new TimeCardNotFoundException(
                'No time card was found for the week of ' +
                String.valueOf(request.workDate) +
                '. Create your weekly time card before logging time.'
            );
        }

        // The user explicitly chose an existing entry to edit in the panel.
        if (request.timeEntryId != null) {
            return updateTargetedEntry(request, card);
        }

        String externalId = resolveExternalId(request, card.Id);

        // The event automation may already have drafted this entry. Matching on
        // the shared key makes the panel edit that draft instead of colliding
        // with the unique ExternalID__c constraint.
        EG_Time_Entry__c existing = timeEntrySelector.findByExternalId(externalId);
        if (existing != null) {
            applyRequest(existing, request);
            update as user existing;
            return new TimeEntryResult(existing.Id, card.Id, true);
        }

        EG_Time_Entry__c entry = buildEntry(request, card.Id, externalId);
        insert as user entry;

        return new TimeEntryResult(entry.Id, card.Id, false);
    }

    /**
     * @description Lists the entries the running user has already logged on a
     * date, so the panel can offer them for editing instead of adding a second
     * entry for the same meeting.
     * @param workDate The date to inspect.
     * @return Summaries for the panel; empty when no card covers the date.
     */
    public List<TimeEntrySummary> getEntriesForDate(Date workDate) {
        List<TimeEntrySummary> summaries = new List<TimeEntrySummary>();
        if (workDate == null) {
            return summaries;
        }
        EG_Time_Card__c card = timeCardSelector.findCardForDate(UserInfo.getUserId(), workDate);
        if (card == null) {
            return summaries;
        }
        for (EG_Time_Entry__c entry : timeEntrySelector.findByDate(card.Id, workDate)) {
            summaries.add(new TimeEntrySummary(entry));
        }
        return summaries;
    }

    /**
     * Updates the specific entry the user selected in the panel. Unlike the
     * key-matched path, the form here was seeded from the record itself, so the
     * submitted values are written verbatim.
     */
    private TimeEntryResult updateTargetedEntry(TimeEntryRequest request, EG_Time_Card__c card) {
        EG_Time_Entry__c existing = timeEntrySelector.findById(request.timeEntryId);
        if (existing == null) {
            throw new InvalidSelectionException('That time entry is no longer available.');
        }
        // The card was resolved from the running user and the submitted date, so
        // this single check rejects both another user's entry and a date that
        // moved the entry into a different week.
        if (existing.EG_Time_Card__c != card.Id) {
            throw new InvalidSelectionException(
                'That time entry belongs to a different time card. Keep the date within the same week, or create a new entry.'
            );
        }

        String newKey = resolveKeyForEdit(existing, request, card.Id);

        existing.Date__c = request.workDate;
        existing.Hours_Worked__c = request.hoursWorked;
        existing.Notes__c = request.notes;
        existing.Time_Category__c = request.timeCategory;
        existing.Internal__c = request.internal == true;
        existing.Opportunity__c = request.opportunityId;
        existing.EG_Project__c = request.projectId;
        existing.EG_Project_Task__c = request.projectTaskId;
        existing.ExternalID__c = newKey;
        update as user existing;

        return new TimeEntryResult(existing.Id, card.Id, true);
    }

    /**
     * Re-derives the key for an edited entry so it keeps describing its own
     * values. Refuses the edit when the resulting key already belongs to a
     * different entry, which would otherwise fail as an opaque duplicate-value
     * database error.
     */
    private String resolveKeyForEdit(
        EG_Time_Entry__c existing,
        TimeEntryRequest request,
        Id timeCardId
    ) {
        if (String.isNotBlank(request.externalId)) {
            return request.externalId;
        }
        String newKey = TimeEntryKey.build(
            timeCardId,
            request.projectId,
            request.projectTaskId,
            request.workDate
        );
        if (newKey == existing.ExternalID__c) {
            return newKey;
        }
        EG_Time_Entry__c clash = timeEntrySelector.findByExternalId(newKey);
        if (clash != null && clash.Id != existing.Id) {
            throw new InvalidSelectionException(
                'Another time entry already covers that project, task, and date. Edit that entry instead.'
            );
        }
        return newKey;
    }

    /**
     * Uses an explicitly supplied external id when a caller provides one,
     * otherwise derives the canonical key shared with the event automation.
     */
    private String resolveExternalId(TimeEntryRequest request, Id timeCardId) {
        if (String.isNotBlank(request.externalId)) {
            return request.externalId;
        }
        return TimeEntryKey.build(
            timeCardId,
            request.projectId,
            request.projectTaskId,
            request.workDate
        );
    }

    /**
     * Applies reviewed values onto an entry that already exists. Hours are
     * replaced outright because the panel value is what the user just confirmed.
     * Optional text and picklist values are only written when supplied, so an
     * untouched form field cannot blank out data the automation populated.
     */
    private void applyRequest(EG_Time_Entry__c entry, TimeEntryRequest request) {
        entry.Hours_Worked__c = request.hoursWorked;
        if (String.isNotBlank(request.notes)) {
            entry.Notes__c = request.notes;
        }
        if (String.isNotBlank(request.timeCategory)) {
            entry.Time_Category__c = request.timeCategory;
        }
        if (request.internal != null) {
            entry.Internal__c = request.internal;
        }
    }

    /**
     * Validates the optional Opportunity/Project/Task selections and back-fills
     * any missing parents from the child records. The UI enforces a top-down
     * flow, but the server re-verifies so an inconsistent combination can never
     * be persisted, regardless of how the request was constructed.
     */
    private void validateAndResolveSelections(TimeEntryRequest request) {
        if (request.projectTaskId != null) {
            EG_Project_Task__c task = projectTaskSelector
                .getByIds(new Set<Id>{ request.projectTaskId })
                .get(request.projectTaskId);
            if (task == null) {
                throw new InvalidSelectionException('The selected project task is not accessible.');
            }
            if (request.projectId == null) {
                request.projectId = task.EG_Project__c;
            } else if (request.projectId != task.EG_Project__c) {
                throw new InvalidSelectionException('The selected task does not belong to the selected project.');
            }
        }

        if (request.projectId != null) {
            EG_Project__c project = projectSelector
                .getByIds(new Set<Id>{ request.projectId })
                .get(request.projectId);
            if (project == null) {
                throw new InvalidSelectionException('The selected project is not accessible.');
            }
            if (request.opportunityId == null) {
                request.opportunityId = project.Linked_Opportunity__c;
            } else if (request.opportunityId != project.Linked_Opportunity__c) {
                throw new InvalidSelectionException('The selected project does not belong to the selected opportunity.');
            }
        }
    }

    /** Fails fast on missing/invalid input before touching the database. */
    private void validateRequest(TimeEntryRequest request) {
        if (request == null) {
            throw new IllegalArgumentException('Request must not be null.');
        }
        if (request.workDate == null) {
            throw new IllegalArgumentException('A work date is required.');
        }
        if (request.hoursWorked == null || request.hoursWorked <= 0) {
            throw new IllegalArgumentException('Hours worked must be greater than zero.');
        }
    }

    /** Maps the DTO onto a new time entry under the resolved time card. */
    private EG_Time_Entry__c buildEntry(
        TimeEntryRequest request,
        Id timeCardId,
        String externalId
    ) {
        return new EG_Time_Entry__c(
            EG_Time_Card__c = timeCardId,
            Date__c = request.workDate,
            Hours_Worked__c = request.hoursWorked,
            Notes__c = request.notes,
            Time_Category__c = request.timeCategory,
            Internal__c = request.internal == true,
            Created_with_Automation__c = true,
            Time_Entry_Source__c = 'Outlook_Panel',
            ExternalID__c = externalId,
            Source_Event_Id__c = String.valueOf(request.sourceEventId),
            Opportunity__c = request.opportunityId,
            EG_Project__c = request.projectId,
            EG_Project_Task__c = request.projectTaskId
        );
    }
}