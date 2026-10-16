/**
 * @description Thin @AuraEnabled controller exposed to the Outlook time-entry LWC.
 *
 * Holds no business logic; it only adapts between the LWC and the service layer
 * and translates service exceptions into AuraHandledExceptions with
 * user-friendly messages. Keeping the controller thin means the same logic can
 * be reused later from Flow, a REST endpoint, or batch code without change.
 */
public with sharing class TimeEntryController {
    /**
     * @description Creates a time entry from the Outlook panel submission, or
     * updates the existing entry when one already matches the canonical key.
     * @param request The user-reviewed values from the Outlook event panel.
     * @return The entry Id, the resolved time card Id, and whether an existing
     * entry was updated.
     * @throws AuraHandledException with a friendly message on any failure.
     */
    @AuraEnabled
    public static TimeEntryService.TimeEntryResult createTimeEntry(TimeEntryRequest request) {
        try {
            return new TimeEntryService().createEntry(request);
        } catch (Exception e) {
            // The service raises typed, message-bearing exceptions
            // (TimeCardNotFoundException, IllegalArgumentException). Re-wrap as
            // AuraHandledException so the LWC receives a clean, user-facing message.
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Lists the entries the running user already logged on a date,
     * letting the panel surface an automation-created entry for editing.
     * Not cacheable: entries can be created by the event automation at any time,
     * and a stale list would invite duplicates.
     * @param workDate The date shown in the panel.
     * @return Summaries of existing entries; empty when none or no time card.
     * @throws AuraHandledException with a friendly message on any failure.
     */
    @AuraEnabled
    public static List<TimeEntrySummary> getEntriesForDate(Date workDate) {
        try {
            return new TimeEntryService().getEntriesForDate(workDate);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}