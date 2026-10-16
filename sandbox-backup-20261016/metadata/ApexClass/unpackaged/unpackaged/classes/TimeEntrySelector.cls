/**
 * @description Selector layer for EG_Time_Entry__c.
 *
 * Centralizes SOQL so the service stays free of inline queries and the
 * find-by-key lookup can be reused by future callers (Flow, REST, batch).
 */
public with sharing class TimeEntrySelector {
    /**
     * @description Finds the entry carrying a given external id.
     * ExternalID__c is a unique external-id field, so at most one row matches.
     * @param externalId The canonical key from TimeEntryKey.build.
     * @return The matching entry, or null when none exists (or it isn't visible).
     */
    public EG_Time_Entry__c findByExternalId(String externalId) {
        if (String.isBlank(externalId)) {
            return null;
        }
        List<EG_Time_Entry__c> entries = [
            SELECT Id, EG_Time_Card__c, Date__c, Hours_Worked__c, Notes__c,
                   Time_Category__c, Internal__c, ExternalID__c
            FROM EG_Time_Entry__c
            WHERE ExternalID__c = :externalId
            WITH USER_MODE
            LIMIT 1
        ];
        return entries.isEmpty() ? null : entries[0];
    }

    /**
     * @description Lists the entries already logged on a date under one time card.
     *
     * Scoped by date rather than by project on purpose: automation-created
     * entries frequently have no project yet, and those are precisely the rows
     * the user needs to see and correct.
     * @param timeCardId The owning weekly time card.
     * @param workDate The date to list entries for.
     * @return Matching entries with project/task names resolved, oldest first.
     */
    public List<EG_Time_Entry__c> findByDate(Id timeCardId, Date workDate) {
        if (timeCardId == null || workDate == null) {
            return new List<EG_Time_Entry__c>();
        }
        return [
            SELECT Id, Hours_Worked__c, Notes__c, Time_Category__c, Internal__c,
                   Created_with_Automation__c, ExternalID__c,
                   EG_Project__c, EG_Project__r.Name,
                   EG_Project_Task__c, EG_Project_Task__r.Name
            FROM EG_Time_Entry__c
            WHERE EG_Time_Card__c = :timeCardId
              AND Date__c = :workDate
            WITH USER_MODE
            ORDER BY CreatedDate ASC
            LIMIT 200
        ];
    }

    /**
     * @description Loads one entry by Id, including the fields needed to verify
     * ownership and re-stamp its key.
     * @param timeEntryId The entry to load.
     * @return The entry, or null when it does not exist or is not visible.
     */
    public EG_Time_Entry__c findById(Id timeEntryId) {
        if (timeEntryId == null) {
            return null;
        }
        List<EG_Time_Entry__c> entries = [
            SELECT Id, EG_Time_Card__c, Date__c, Hours_Worked__c, Notes__c,
                   Time_Category__c, Internal__c, ExternalID__c,
                   EG_Project__c, EG_Project_Task__c
            FROM EG_Time_Entry__c
            WHERE Id = :timeEntryId
            WITH USER_MODE
            LIMIT 1
        ];
        return entries.isEmpty() ? null : entries[0];
    }
}