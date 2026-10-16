/**
 * Class to manage libraries, account entitlements, and contact preferences.
 */
public with sharing class EntitlementsHandler {

    /**
     * Handles creating campaigns for new libraries.
     *
     * @newList list of new libraries created
     */
    public static void onLibraryInsert(List<Library__c> newList) {
        List<Campaign> campaigns = new List<Campaign>();
        for (Library__c l : newList) {
            // Each distribution category has a Macro category under it - give these unique names
            String campName = l.Name;
            if (l.Name == 'Macro') 
                campName = l.Portal_Display_Name__c;

            // Create a campaign for notifications for Individual Email Subscriptions
            Campaign c = new Campaign();
            c.Name = campName + ' Individual Email Subscriptions';
            c.Tag__c = l.Id;
            c.IsActive = true;
            c.Type = 'Portal Distribution List';
            campaigns.add(c);

            // Create a campaign for notifications for Summary Email Subscriptions
            Campaign c2 = new Campaign();
            c2.Name = campName + ' Summary Email Subscriptions';
            c2.Tag__c = l.Id;
            c2.IsActive = true;
            c2.Type = 'Portal Distribution List';
            campaigns.add(c2);
            
            system.debug('### c.tag__c and c2.tag__c = ' + c.Tag__c + ' ' +c2.tag__c);
        }

        insert campaigns;
    }

    /**
     * Helper method to fetch campaigns related to a list of contact preferences
     *
     * @prefs list of contact preferences for which to fetch campaigns
     * @libraries map to be filled in with account preference ID to library ID
     * @return map of campaign ID to campaign for all campaigns related to input prefs
     */
    private static Map<Id, Campaign> getCampaigns(List<Contact_Preferences__c> prefs, Map<Id, Id> libraries) {
        Set<Id> aPrefSet = new Set<Id>();
        // Fetch all account preferences
        for (Contact_Preferences__c cPref : prefs) {
            system.debug('### cpref.account_preferences__c = ' + cpref.account_preferences__c);
            aPrefSet.add(cPref.Account_Preferences__c);
        }

        List<Account_Preferences__c> aPrefs = [SELECT Id, Library__c FROM Account_Preferences__c WHERE Id IN :aPrefSet AND Library__r.Active__c != FALSE];

        // Fetch libraries related to account preferences
        for (Account_Preferences__c aPref : aPrefs) {
            
            system.debug('### apref.Library__c = ' + apref.Library__c);        
            libraries.put(aPref.Id, aPref.Library__c);
        }

        // Fetch campaigns related to libraries
        Map<Id, Campaign> campaigns = new Map<Id, Campaign>([SELECT Id, Name, Send_Attachments__c, Tag__c FROM Campaign WHERE Tag__c IN :libraries.values()]);
        return campaigns;
    }

    /**
     * Helper method to get contact records associated with a list of contact preferences
     *
     * @cList list of contact preferences for which to fetch contacts
     * @return map of contact ID to contact for all related contacts
     */
    private static Map<Id, Contact> getContacts(List<Contact_Preferences__c> cList) {
        Set<Id> contactIds = new Set<Id>();
        for (Contact_Preferences__c cPref : cList) {
            contactIds.add(cPref.Contact__c);
        }

        //Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT ID, Receive_Attachments__c, pi__url__c FROM Contact WHERE Id IN :contactIds]);
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT ID, Status__c, Receive_Attachments__c, pi__url__c FROM Contact WHERE Id IN :contactIds]);
        return contactMap;
    }
    
    /**
     * Handles Campaign Member creation and Pardot email list syncing for new contact preferences
     *
     * @newList list of new contact preferences
     */
    public static void onCPrefInsert(List<Contact_Preferences__c> newList) {
        List<String> contactURLs = new List<String>();
        List<String> campaignNames = new List<String>();
        Map<Id, Id> libraries = new Map<Id, Id>();

        // Get campaigns and contacts related to input preferences
        Map<Id, Campaign> campaigns = getCampaigns(newList, libraries);
        system.debug('### campaigns = ' + campaigns);        
        Map<Id, Contact> contacts = getContacts(newList);
        
        Map<Id, Campaign> campaignMap = new Map<Id, Campaign>();
        Map<Id, Campaign> summaryEmailCampaignMap = new Map<Id, Campaign>();
        Map<Id, Campaign> attachmentMap = new Map<Id, Campaign>();
        // Construct maps of library ID to campaign for Individual and Summary email campaigns
        for (Campaign c : campaigns.values()) {
            if (c.Name.contains('Individual Email'))
                campaignMap.put(c.Tag__c, c);
            if (c.Name.contains('Summary Email'))
                summaryEmailCampaignMap.put(c.Tag__c, c);
        }

        // Add campaign members to correct campaign based on contact's attachment choice
        List<CampaignMember> memberUpdates = new List<CampaignMember>();
       
        for (Contact_Preferences__c cPref : newList) {
            system.debug('### cPref.Individual_Emails__c = ' + cPref.Individual_Emails__c);        
            // 8-21-18 Bolterra - adding code to ensure only adding to a campaign if Contact Preference has Individual Emails checked and Status = Enabled
            if (cPref.Preference_Type__c != 'Distribution List')
                continue;   
                 
            if (contacts.get(cPref.Contact__c) != null && contacts.get(cPref.Contact__c).Status__c != null && contacts.get(cPref.Contact__c).Status__c == 'Enabled') {                                               
                if (cPref.Individual_Emails__c == TRUE) {
                    CampaignMember cMem = new CampaignMember();
                    cMem.ContactId = cPref.Contact__c;
                    
                        if (campaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null)
                            cMem.CampaignId = campaignMap.get(libraries.get(cPref.Account_Preferences__c)).Id;
                        contactURLs.add(contacts.get(cPref.Contact__c).pi__url__c);
                        if (campaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null)
                            campaignNames.add(campaignMap.get(libraries.get(cPref.Account_Preferences__c)).Name);
                        //system.debug('### cMem = ' + cMem); 
                                           
                        memberUpdates.add(cMem);
                        //system.debug('### memberUpdates = ' + memberUpdates);
                }
                                       
                if (cPref.Summary_Emails__c == TRUE) {
                    CampaignMember cMem = new CampaignMember();
                    cMem.ContactId = cPref.Contact__c;
                     
                        if (summaryEmailCampaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null)            
                            cMem.CampaignId = summaryEmailCampaignMap.get(libraries.get(cPref.Account_Preferences__c)).Id;
                        contactURLs.add(contacts.get(cPref.Contact__c).pi__url__c);
                        if (summaryEmailCampaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null)
                            campaignNames.add(summaryEmailCampaignMap.get(libraries.get(cPref.Account_Preferences__c)).Name);
                        //system.debug('### cMem = ' + cMem);                    
               
                        memberUpdates.add(cMem);
                        //system.debug('### memberUpdates = ' + memberUpdates);
                }
            }                   
        /*       
            if (cPref.Individual_Emails__c == TRUE && contacts.get(cPref.Contact__c) != null && contacts.get(cPref.Contact__c).Status__c != null && contacts.get(cPref.Contact__c).Status__c == 'Enabled') {                                               

                CampaignMember cMem = new CampaignMember();
                cMem.ContactId = cPref.Contact__c;
                
                //if (contacts.get(cPref.Contact__c).Receive_Attachments__c) {
                    // Add to attachment campaign             
                    //cMem.CampaignId = attachmentMap.get(libraries.get(cPref.Account_Preferences__c)).Id;
                //} else {
                    // Add to non-attachment campaign and Pardot email list

                    if (campaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null)
                        cMem.CampaignId = campaignMap.get(libraries.get(cPref.Account_Preferences__c)).Id;
                    contactURLs.add(contacts.get(cPref.Contact__c).pi__url__c);
                    if (campaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null)
                    campaignNames.add(campaignMap.get(libraries.get(cPref.Account_Preferences__c)).Name);
                    system.debug('### cMem = ' + cMem);                    
                //}
                memberUpdates.add(cMem);
                system.debug('### memberUpdates = ' + memberUpdates);
            }
            
            if (cPref.Summary_Emails__c == TRUE && contacts.get(cPref.Contact__c).Status__c != null && contacts.get(cPref.Contact__c).Status__c == 'Enabled') {                                               

                CampaignMember cMem = new CampaignMember();
                cMem.ContactId = cPref.Contact__c;
                
                //if (contacts.get(cPref.Contact__c).Receive_Attachments__c) {
                    // Add to attachment campaign             
                    //cMem.CampaignId = attachmentMap.get(libraries.get(cPref.Account_Preferences__c)).Id;
                //} else {
                    // Add to non-attachment campaign and Pardot email list
                    system.debug('### Add to summary email campaign');    
                    if (summaryEmailCampaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null)            
                        cMem.CampaignId = summaryEmailCampaignMap.get(libraries.get(cPref.Account_Preferences__c)).Id;
                    contactURLs.add(contacts.get(cPref.Contact__c).pi__url__c);
                    if (summaryEmailCampaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null)
                    campaignNames.add(summaryEmailCampaignMap.get(libraries.get(cPref.Account_Preferences__c)).Name);
                    system.debug('### cMem = ' + cMem);                    
                //}
                memberUpdates.add(cMem);
                system.debug('### memberUpdates = ' + memberUpdates);
            }            
           */           
        }

        // Sync updates to portal and Pardot
        //PortalAPIEntitlements.sendContactPreferences(newList, libraries, true);
        //PardotAPIUtils.updateEmailLists(contactURLs, campaignNames, true);

        // Some campaign members may already exist - ensure other inserts still happen regardless
        Database.insert(memberUpdates, false);
    }

    
    /**
     * Handle contact disablement
     *
     * @oldMap map of ID to preference before update
     */

    public static void onContactStatusDisablement() {
        
    
    }    
    /**
     * Sync changes to daily summary selections to portal when they change
     *
     * @oldMap map of ID to preference before update
     * @newMap map of ID to preference after update
     */
    // 8-21-18 Bolterra - Updating to add call to onCPrefInsert when Individual Emails has been checked and onCPrefDelete when Individual Emails has been unchecked
    // 10-13-18 further updates to handle summary email changes
    public static void onCPrefUpdate(Map<Id, Contact_Preferences__c> oldMap, Map<Id, Contact_Preferences__c> newMap) {
        List<Contact_Preferences__c> summaryEmailChanged = new List<Contact_Preferences__c>();
        List<Contact_Preferences__c> emailUnchecked = new List<Contact_Preferences__c>();   
        List<Contact_Preferences__c> emailChecked = new List<Contact_Preferences__c>();    
                          
        // Locate if preference update was to daily summary selection
        Set<Id> accPrefIds = new Set<Id>();         
        for (Id cID : oldMap.keySet()) {
        system.debug('### newMap.get(cID) = ' + newMap.get(cID));          
            if (oldMap.get(cID).Summary_Emails__c != newMap.get(cID).Summary_Emails__c) {
                summaryEmailChanged.add(newMap.get(cID));
            }
            if (oldMap.get(cID).Summary_Emails__c != newMap.get(cID).Summary_Emails__c && !newMap.get(cID).Summary_Emails__c) {
                if (!newMap.get(cID).Summary_Emails__c) emailUnchecked.add(newMap.get(cID));
            } else if (newMap.get(cID).Summary_Emails__c) emailChecked.add(newMap.get(cID));      
                   
            if (oldMap.get(cID).Individual_Emails__c != newMap.get(cID).Individual_Emails__c && !newMap.get(cID).Individual_Emails__c) {
                if (!newMap.get(cID).Individual_Emails__c) emailUnchecked.add(newMap.get(cID));
            } else if (newMap.get(cID).Individual_Emails__c) emailChecked.add(newMap.get(cID)); 
                      
        }

        Map<Id, Id> libraries = new Map<Id, Id>(); 
        Map<Id, Campaign> campaigns = getCampaigns(newMap.values(), libraries);
        system.debug('### summaryEmailChanged.size()  individualEmailUnchecked.size()  individualEmailChecked.size()=' +summaryEmailChanged.size() +' ' + emailUnchecked.size() + ' ' +emailChecked.size());
        // Sync changes to portal
        /*
        if (summaryEmailChanged.size() > 0)
            PortalAPIEntitlements.sendContactPreferences(summaryEmailChanged, libraries, true);
        */     
        // Leverage onCPrefDelete method for when Individual Emails is unchecked as both cause the removal of the CampaignMember record etc
        if (emailUnchecked.size() > 0)
            onCPrefDelete(emailUnchecked);           
            
        // Leverage onCPrefInsert method for when Individual Emails is checked as both cause the addition of the CampaignMember record etc
        system.debug('### emailChecked = ' + emailChecked);        
        if (emailChecked.size() > 0)
            onCPrefInsert(emailChecked);               
    }

    /**
     * Manage campaign membership and Pardot lists when a contact preference is deleted
     *
     * @deletedList list of deleted preferences
     */
    public static void onCPrefDelete(List<Contact_Preferences__c> deletedList) {
        Set<Id> contactSet = new Set<Id>();

        // Find campaigns related to deleted preferences
        for (Contact_Preferences__c cPref : deletedList) {
            contactSet.add(cPref.Contact__c);
        }

        List<String> contactURLs = new List<String>();
        List<String> campaignNames = new List<String>();
        Map<Id, Id> libraries = new Map<Id, Id>();
        Map<Id, Campaign> campaigns = getCampaigns(deletedList, libraries);
        Map<Id, Contact> contacts = getContacts(deletedList);

        Map<Id, Campaign> campaignMap = new Map<Id, Campaign>();
        Map<Id, Campaign> attachmentMap = new Map<Id, Campaign>();
        // Map campaigns to library ID for both attachment and non-attachment campaigns
        for (Campaign c : campaigns.values()) {
            if (c.Send_Attachments__c)
                attachmentMap.put(c.Tag__c, c);
            else
                campaignMap.put(c.Tag__c, c);
        }

        List<CampaignMember> members = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId IN :contactSet];
        List<CampaignMember> toDelete = new List<CampaignMember>();
        for (Contact_Preferences__c cPref : deletedList) {
            for (CampaignMember member : members) {
                // Find campaign member matching this contact and campaign and delete it
                if (member.ContactId == cPref.Contact__c && 
                    (   (campaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null 
                        && member.CampaignId == campaignMap.get(libraries.get(cPref.Account_Preferences__c)).Id) ||
                        (attachmentMap.get(libraries.get(cPref.Account_Preferences__c)) != null &&
                        member.CampaignId == attachmentMap.get(libraries.get(cPref.Account_Preferences__c)).Id)
                    )) {
                        toDelete.add(member);
                        // If this was a non-attachment campaign, remove it from the Pardot list as well
                        if (campaignMap.get(libraries.get(cPref.Account_Preferences__c)) != null 
                            && member.CampaignId == campaignMap.get(libraries.get(cPref.Account_Preferences__c)).Id) {
                            contactURLs.add(contacts.get(cPref.Contact__c).pi__url__c);
                            campaignNames.add(campaignMap.get(libraries.get(cPref.Account_Preferences__c)).Name);
                        }
                }
            }
        }

        // Sync changes to portal and Pardot
        //PortalAPIEntitlements.sendContactPreferences(deletedList, libraries, false);
        //PardotAPIUtils.updateEmailLists(contactURLs, campaignNames, false);
        
        Set<CampaignMember> toDeleteSet = new Set<CampaignMember>(toDelete);
        List<CampaignMember> dupeFreeToDelete = new List<CampaignMember>();

        //4-9-18 Bolterra - error generated by attempting to delete a list of campaignmembers containing duplicate
        //elements due to duplicate contact preferences being created. adding elements to a set then back to list   
        //delete toDelete;
        toDeleteSet.addAll(toDelete);
        dupeFreeToDelete.addAll(toDeleteSet);
        
        delete dupeFreeToDelete;
    }

    /**
     * Sync entitlement changes to portal
     *
     * @newList list of changed entitlements
     * @isInsert whether or not the entitlements were inserted or are being deleted
     */
     /*
    public static void onAPrefChange(List<Account_Preferences__c> newList, Boolean isInsert) {
        Map<Id, AccountEntitlementMap> entitlementMap = new Map<Id, AccountEntitlementMap>();

        // Build set of changed entitlements
        for (Account_Preferences__c aPref : newList) {
            if (!entitlementMap.containsKey(aPref.Account__c)) {
                entitlementMap.put(aPref.Account__c, new AccountEntitlementMap(aPref.Account__c));
            }
            AccountEntitlementMap entMap = entitlementMap.get(aPref.Account__c);
            // Send changes for either new entitlements or removed entitlements
            entMap.entitlements.put(aPref.Library__c, isInsert);
        }

        List<AccountEntitlementMap> entitlementList = entitlementMap.values();
        List<InboundMessage> inboundList = new List<InboundMessage>();
        List<String> messages = new List<String>();
        List<String> titles = new List<String>();

        // Build list of changes
        for (AccountEntitlementMap m : entitlementList) {
            titles.add('Account: ' + m.salesforceAccountId);
            inboundList.add(new InboundMessage('UpdateEntitlements', m));
        }

        for (InboundMessage m : inboundList) {
            messages.add(JSON.serialize(m));
        }

        // Send to portal
        //PortalAPICallout.writeInboundQueueItems(titles, messages);
    }
*/
    /**
     * Wrapper class to aid in serializing messages to portal
     */ /*
    public class InboundMessage {
        String messageType;
        AccountEntitlementMap messageDetails;

        public InboundMessage(String msgType, AccountEntitlementMap msgDetails) {
            messageType = msgType;
            messageDetails = msgDetails;
        }
    }
*/
    /**
     * Wrapper class to hold account entitlements for an account
     */ /*
    public class AccountEntitlementMap {
        Id salesforceAccountId;
        Map<String, Boolean> entitlements;

        public AccountEntitlementMap(Id accountId) {
            salesforceAccountId = accountId;
            entitlements = new Map<String, Boolean>();
        }
    }
    */
}