/**
 * Batch class to aid in deployment of portal. Creates campaign members to match contact preferences.
 */
global class PortalAddCampaignSEMembersBatch implements Database.Batchable<sObject> {
    
    global Map<Id, Campaign> campaigns;
    
    /**
     * Collect campaigns and libraries for all distribution lists
     */
    global PortalAddCampaignSEMembersBatch() {
        campaigns = new Map<Id, Campaign>();
        List<Campaign> campaignList = [SELECT Id, Tag__c FROM Campaign WHERE Type = 'Portal Distribution List' and Name LIKE '%Summary Email Subscriptions%'];
        for (Campaign cmp : campaignList) {
            campaigns.put(cmp.Tag__c, cmp);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {        
        return Database.getQueryLocator([SELECT Id, Account_Preferences__c, Contact__c, Contact__r.Status__c, Individual_Emails__c, Preference_Type__c FROM Contact_Preferences__c WHERE Preference_Type__c = 'Distribution List' AND Contact__r.Status__c = 'Enabled' AND Summary_Emails__c = true]);
    }

    /**
     * Create a campaign member for each contact preference
     */
    global void execute(Database.BatchableContext bc, List<Contact_Preferences__c> cPrefList) {
        Set<Id> accPrefIds = new Set<ID>();
        for (Contact_Preferences__c cPref : cPrefList) {
            accPrefIds.add(cPref.Account_Preferences__c);
        }
        List<Account_Preferences__c> aPrefList = [SELECT Id, Library__c FROM Account_Preferences__c WHERE Id IN :accPrefIds];
        Map<Id, Id> libraries = new Map<Id, Id>();
        for (Account_Preferences__c aPref : aPrefList) {
            libraries.put(aPref.Id, aPref.Library__c);
        }

        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        for (Contact_Preferences__c cPref : cPrefList) {
            if (!libraries.containsKey(cPref.Account_Preferences__c))
                continue;
            Id libID = libraries.get(cPref.Account_Preferences__c);
            if (!campaigns.containsKey(libID))
                continue;
            CampaignMember cMem = new CampaignMember(ContactId = cPref.Contact__c, CampaignId = campaigns.get(libID).Id);
            campaignMembers.add(cMem);
        }
        Database.insert(campaignMembers, false);
    }

    global void finish(Database.BatchableContext bc) {

    }
    
}