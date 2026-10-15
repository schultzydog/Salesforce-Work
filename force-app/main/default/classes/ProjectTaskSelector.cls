/**
 * @description Selector layer for EG_Project_Task__c. Centralizes SOQL so
 * relationship validation and Time Category defaulting reuse one query.
 */
public with sharing class ProjectTaskSelector {
    /**
     * @description Returns the requested project tasks keyed by Id, including the
     * parent Project link and the task's own Time Category.
     * @param taskIds Project Task Ids to load.
     * @return Map of Id to EG_Project_Task__c (only accessible records returned).
     */
    public Map<Id, EG_Project_Task__c> getByIds(Set<Id> taskIds) {
        Map<Id, EG_Project_Task__c> result = new Map<Id, EG_Project_Task__c>();
        if (taskIds == null || taskIds.isEmpty()) {
            return result;
        }
        for (EG_Project_Task__c task : [
            SELECT Id, EG_Project__c, Time_Category__c
            FROM EG_Project_Task__c
            WHERE Id IN :taskIds
            WITH USER_MODE
        ]) {
            result.put(task.Id, task);
        }
        return result;
    }
}