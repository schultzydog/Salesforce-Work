/**
 * @description Builds the canonical EG_Time_Entry__c.ExternalID__c value.
 *
 * This key is the contract between the two writers of time entries: the
 * event-driven automation (egEventLogic) and the Outlook panel (TimeEntryService).
 * Both must produce the identical string so the panel edits the entry the
 * automation already created instead of inserting a duplicate.
 *
 * Format: {TimeCardId}:{ProjectId}:{ProjectTaskId}:{Date}
 * Null lookups render as the literal "null" and the date renders as
 * "yyyy-MM-dd HH:mm:ss" -- both are artifacts of Apex string concatenation that
 * the existing data depends on, so concatenation is used deliberately here.
 * String.valueOf(Date) would emit "yyyy-MM-dd" and never match stored keys.
 */
public with sharing class TimeEntryKey {
    /**
     * @description Builds the external id for a time entry.
     * @param timeCardId The owning weekly time card.
     * @param projectId The related project, or null.
     * @param projectTaskId The related project task, or null.
     * @param workDate The date the work was performed.
     * @return The canonical external id string.
     */
    public static String build(
        Id timeCardId,
        Id projectId,
        Id projectTaskId,
        Date workDate
    ) {
        return timeCardId + ':' + projectId + ':' + projectTaskId + ':' + workDate;
    }
}