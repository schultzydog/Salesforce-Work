trigger ContactPreferenceTrigger on Contact_Preferences__c (before insert, before delete, before update) {
    Portal_Setting__mdt settings = [SELECT Account_and_Contact_Pref_Triggers_Active__c FROM Portal_Setting__mdt WHERE DeveloperName = 'Active_Settings'];
    if (settings.Account_and_Contact_Pref_Triggers_Active__c) {
        if (Trigger.isInsert) {
            EntitlementsHandler.onCPrefInsert(Trigger.new);
        } else if (Trigger.isDelete) {
            EntitlementsHandler.onCPrefDelete(Trigger.old);
        } else if (Trigger.isUpdate) {
            EntitlementsHandler.onCPrefUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}