/**
 * @description Selector layer for EG_Time_Card__c.
 *
 * Centralizes all SOQL against the object so queries stay bulk-safe, testable,
 * and free of duplication. Keeping queries here (rather than inline in the
 * service) means the covering-card logic can be reused by future callers such
 * as batch time-entry creation without copy/pasting SOQL.
 */
public with sharing class TimeCardSelector {
    /**
     * @description Finds the time card that covers a given work date for a user.
     * A user has exactly one time card per week, so the covering card is unique.
     * @param ownerId The user who owns the time card (usually UserInfo.getUserId()).
     * @param workDate The date the work was performed.
     * @return The covering EG_Time_Card__c (Id and date fields), or null if none.
     */
    public EG_Time_Card__c findCardForDate(Id ownerId, Date workDate) {
        if (ownerId == null || workDate == null) {
            return null;
        }
        List<EG_Time_Card__c> cards = [
            SELECT Id, OwnerId, Start_Date__c, End_Date__c
            FROM EG_Time_Card__c
            WHERE OwnerId = :ownerId
              AND Start_Date__c <= :workDate
              AND End_Date__c >= :workDate
            WITH USER_MODE
            ORDER BY Start_Date__c DESC
            LIMIT 1
        ];
        return cards.isEmpty() ? null : cards[0];
    }
}