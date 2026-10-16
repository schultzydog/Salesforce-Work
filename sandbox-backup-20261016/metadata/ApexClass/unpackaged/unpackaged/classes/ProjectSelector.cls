/**
 * @description Selector layer for EG_Project__c. Centralizes SOQL so relationship
 * validation (and future AI candidate scoring) reuses one query definition.
 */
public with sharing class ProjectSelector {
    /**
     * @description Returns the requested projects keyed by Id, including the
     * parent Opportunity link used for referential-integrity checks.
     * @param projectIds Project Ids to load.
     * @return Map of Id to EG_Project__c (only accessible records are returned).
     */
    public Map<Id, EG_Project__c> getByIds(Set<Id> projectIds) {
        Map<Id, EG_Project__c> result = new Map<Id, EG_Project__c>();
        if (projectIds == null || projectIds.isEmpty()) {
            return result;
        }
        for (EG_Project__c project : [
            SELECT Id, Linked_Opportunity__c
            FROM EG_Project__c
            WHERE Id IN :projectIds
            WITH USER_MODE
        ]) {
            result.put(project.Id, project);
        }
        return result;
    }
}