/**
 * @description Shared test-data builders for the time-entry feature. Kept in one
 * place so every test class (this phase and later phases) creates data the same
 * way and updates propagate from a single location.
 */
@IsTest
public class TestDataFactory {
    /**
     * @description Inserts a time card owned by the running user covering a week.
     * @param weekStart Start_Date__c value.
     * @param weekEnd End_Date__c value.
     * @return The inserted EG_Time_Card__c.
     */
    public static EG_Time_Card__c newTimeCard(Date weekStart, Date weekEnd) {
        EG_Time_Card__c card = new EG_Time_Card__c(
            Name = 'Test Time Card',
            Start_Date__c = weekStart,
            End_Date__c = weekEnd
        );
        insert card;
        return card;
    }

    /**
     * @description Returns the first active Time_Category__c picklist value, or
     * null if none exist. Resolving dynamically avoids hardcoding org-specific
     * picklist values in tests.
     * @return A valid picklist API value, or null.
     */
    public static String firstTimeCategory() {
        for (Schema.PicklistEntry entry : EG_Time_Entry__c.Time_Category__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }

    /**
     * @description Inserts a minimal Opportunity using a valid active stage.
     * @return The inserted Opportunity.
     */
    public static Opportunity newOpportunity() {
        String stage = [SELECT MasterLabel FROM OpportunityStage WHERE IsActive = true LIMIT 1].MasterLabel;
        Opportunity opp = new Opportunity(
            Name = 'POC Test Opp',
            StageName = stage,
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        return opp;
    }

    /**
     * @description Inserts a project optionally linked to an opportunity.
     * @param opportunityId Opportunity to link, or null.
     * @return The inserted EG_Project__c.
     */
    public static EG_Project__c newProject(Id opportunityId) {
        EG_Project__c project = new EG_Project__c(
            Name = 'POC Test Project',
            Linked_Opportunity__c = opportunityId
        );
        insert project;
        return project;
    }

    /**
     * @description Inserts a project task under a project.
     * @param projectId Parent EG_Project__c.
     * @return The inserted EG_Project_Task__c.
     */
    public static EG_Project_Task__c newProjectTask(Id projectId) {
        EG_Project_Task__c task = new EG_Project_Task__c(
            Name = 'POC Test Task',
            EG_Project__c = projectId
        );
        insert task;
        return task;
    }
}