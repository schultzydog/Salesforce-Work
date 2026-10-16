/**
 * @description Read-only view of an existing EG_Time_Entry__c, shown in the
 * Outlook panel so a user can spot an entry the automation already created and
 * edit it instead of logging a second one.
 *
 * Carries resolved project/task names because the panel renders a list and
 * cannot query related records itself.
 */
public with sharing class TimeEntrySummary {
    @AuraEnabled
    public Id timeEntryId { get; set; }
    @AuraEnabled
    public Decimal hoursWorked { get; set; }
    @AuraEnabled
    public String notes { get; set; }
    @AuraEnabled
    public String timeCategory { get; set; }
    @AuraEnabled
    public Boolean internal { get; set; }
    @AuraEnabled
    public Id projectId { get; set; }
    @AuraEnabled
    public String projectName { get; set; }
    @AuraEnabled
    public Id projectTaskId { get; set; }
    @AuraEnabled
    public String projectTaskName { get; set; }
    /** True when the entry came from the event automation rather than a person. */
    @AuraEnabled
    public Boolean createdWithAutomation { get; set; }

    public TimeEntrySummary(EG_Time_Entry__c entry) {
        this.timeEntryId = entry.Id;
        this.hoursWorked = entry.Hours_Worked__c;
        this.notes = entry.Notes__c;
        this.timeCategory = entry.Time_Category__c;
        this.internal = entry.Internal__c;
        this.projectId = entry.EG_Project__c;
        this.projectName = entry.EG_Project__r == null ? null : entry.EG_Project__r.Name;
        this.projectTaskId = entry.EG_Project_Task__c;
        this.projectTaskName = entry.EG_Project_Task__r == null
            ? null
            : entry.EG_Project_Task__r.Name;
        this.createdWithAutomation = entry.Created_with_Automation__c;
    }
}