public class confCallStagingTriggerHandler {

    public static Map<String, Lead> leadEmailIdMap = new Map<String, Lead>();
    
    public static void processStagingRecords(List<Conference_Call_Staging__c> newccs) {

        Set<String> emails = new Set<String>();
        List<Conference_Call_Staging__c> insertLeads = new List<Conference_Call_Staging__c>();
                   
    }

}