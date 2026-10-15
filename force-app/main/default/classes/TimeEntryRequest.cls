/**
 * @description Data transfer object carrying the user-reviewed values from the
 * Outlook time-entry LWC to Apex.
 *
 * Using a DTO (instead of a long list of loose parameters) keeps the controller
 * and service method signatures stable as later phases add Opportunity, Project,
 * and Project Task selections plus AI suggestion metadata. New inputs become new
 * fields on this class rather than breaking changes to every caller.
 */
public with sharing class TimeEntryRequest {
    /** Date the work was performed. Drives which weekly time card is used. */
    @AuraEnabled
    public Date workDate { get; set; }

    /** Hours worked for this entry. Must be greater than zero. */
    @AuraEnabled
    public Decimal hoursWorked { get; set; }

    /** Free-text notes; prefilled from the Outlook event subject/body. */
    @AuraEnabled
    public String notes { get; set; }

    /** API name of the Time_Category__c picklist value the user selected. */
    @AuraEnabled
    public String timeCategory { get; set; }

    /** Whether the time is internal (non-billable). */
    @AuraEnabled
    public Boolean internal { get; set; }

    /**
     * Outlook event identifier. Stored on EG_Time_Entry__c.ExternalID__c to
     * enable idempotent upserts and duplicate detection in later phases.
     * Optional in Phase 1.
     */
    @AuraEnabled
    public String externalId { get; set; }

    /**
     * Existing entry the user chose to edit in the panel. When set, that record
     * is updated verbatim instead of matching on the external id.
     */
    @AuraEnabled
    public Id timeEntryId { get; set; }

    /**
     * Salesforce Event this entry logs, when the panel matched one. Forms part
     * of the canonical key, so supplying it is what makes the panel converge on
     * the entry the event automation already drafted rather than inserting a
     * second row for the same meeting.
     */
    @AuraEnabled
    public Id sourceEventId { get; set; }

    /** Optional Opportunity to relate the entry to (Phase 2). */
    @AuraEnabled
    public Id opportunityId { get; set; }

    /** Optional Project. Must belong to opportunityId when both are set (Phase 2). */
    @AuraEnabled
    public Id projectId { get; set; }

    /** Optional Project Task. Must belong to projectId when both are set (Phase 2). */
    @AuraEnabled
    public Id projectTaskId { get; set; }
}