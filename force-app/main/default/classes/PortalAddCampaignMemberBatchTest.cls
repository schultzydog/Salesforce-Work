/**
 * Contains tests for the daily summary batch process
 */
@isTest
private class PortalAddCampaignMemberBatchTest {

    @testSetup
    static void testSetup() {
/*    
        // Set up mock to avoid callout errors from inserts
        PardotAPIMock mock = new PardotAPIMock();
        mock.reqType = PardotAPIMock.LIST_TYPE;
        Test.setMock(HttpCalloutMock.class, mock);
*/
        // Set up libraries
        Library__c l = new Library__c(Name = 'Daily Summary');

        Library__c l1 = new Library__c(Name = 'Category 1');
        Library__c l2 = new Library__c(Name = 'Category 2');
        Library__c l3 = new Library__c(Name = 'Category 3');
        insert new List<Library__c>{l, l1, l2, l3};
        Set<Id> lSet = new Set<Id>{l1.Id, l2.Id, l3.Id};

        // Set up account and contact info
        Account a = new Account(Name = 'Test Account',  Conference_Call_Access__c=TRUE, Portal_Access__c=TRUE);
        insert a;
        Opportunity o = new Opportunity(Name = 'Test opp', StageName = 'Prospect', AccountId = a.Id, CloseDate= Date.today());
        insert o;
        a.Status_Enable_Disable__c = 'Enabled';
        update a;
        
        Contact c1 = new Contact(LastName = 'Test 1', AccountId = a.Id, Email='test@test.com', Status__c = 'Enabled',Worldflow_Portal_Access__c=TRUE);
        Contact c2 = new Contact(LastName = 'Test 2', AccountId = a.Id, Email='test2@test.com', Status__c = 'Enabled',Worldflow_Portal_Access__c=TRUE);
        Contact c3 = new Contact(LastName = 'Test 3', AccountId = a.Id, Email='test3@test.com', Status__c = 'Enabled',Worldflow_Portal_Access__c=TRUE);
        insert new List<Contact>{c1, c2, c3};

        // Set up entitlements
        Account_Preferences__c aPref = new Account_Preferences__c(Account__c = a.Id, Library__c = l.Id);

        Account_Preferences__c aPref1 = new Account_Preferences__c(Account__c = a.Id, Library__c = l1.Id);
        Account_Preferences__c aPref2 = new Account_Preferences__c(Account__c = a.Id, Library__c = l2.Id);
        Account_Preferences__c aPref3 = new Account_Preferences__c(Account__c = a.Id, Library__c = l3.Id);
        insert new List<Account_Preferences__c>{aPref, aPref1, aPref2, aPref3};

        // Set up contact preferences for daily summaries
        Contact_Preferences__c cPref_ds1 = new Contact_Preferences__c(Contact__c = c1.Id, Account_Preferences__c = aPref.Id, Summary_Emails__c = true,Individual_Emails__c = true);
        Contact_Preferences__c cPref_ds2 = new Contact_Preferences__c(Contact__c = c2.Id, Account_Preferences__c = aPref.Id, Summary_Emails__c = true,Individual_Emails__c = true);
        Contact_Preferences__c cPref_ds3 = new Contact_Preferences__c(Contact__c = c3.Id, Account_Preferences__c = aPref.Id, Summary_Emails__c = true,Individual_Emails__c = true);
        // and for categories
        Contact_Preferences__c cPref_c1_l1 = new Contact_Preferences__c(Contact__c = c1.Id, Account_Preferences__c = aPref1.Id, Summary_Emails__c = true, Individual_Emails__c = true);
        Contact_Preferences__c cPref_c1_l2 = new Contact_Preferences__c(Contact__c = c1.Id, Account_Preferences__c = aPref2.Id, Summary_Emails__c = true, Individual_Emails__c = true);
        Contact_Preferences__c cPref_c2_l2 = new Contact_Preferences__c(Contact__c = c2.Id, Account_Preferences__c = aPref2.Id, Summary_Emails__c = true, Individual_Emails__c = true);
        Contact_Preferences__c cPref_c3_l2 = new Contact_Preferences__c(Contact__c = c3.Id, Account_Preferences__c = aPref2.Id, Summary_Emails__c = true, Individual_Emails__c = true);
        Contact_Preferences__c cPref_c3_l3 = new Contact_Preferences__c(Contact__c = c3.Id, Account_Preferences__c = aPref3.Id, Summary_Emails__c = false);

        insert new List<Contact_Preferences__c>{cPref_ds1, cPref_ds2, cPref_ds3, cPref_c1_l1, cPref_c1_l2, cPref_c2_l2, cPref_c3_l2, cPref_c3_l3};

        // Set up a user to act as an author
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', ProfileId = p.Id, 
                            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@eurasia-testorg.com');
        insert u;

    }
    
    /**
     * Test that the batch process correctly compiles daily summaries
     */
    @isTest 
    static void testBatch() {
/*    
        PardotAPIMock mock = new PardotAPIMock();
        mock.reqType = PardotAPIMock.LIST_TYPE;
        Test.setMock(HttpCalloutMock.class, mock);
*/
        List<Library__c> libs = [SELECT Id FROM Library__c WHERE Name != 'Daily Summary'];
        Set<Id> lSet = new Set<Id>();
        for (Library__c l : libs) {
            lSet.add(l.Id);
        }

        Test.startTest();
        PortalAddCampaignMembersBatch b = new PortalAddCampaignMembersBatch();
        Id batchId = Database.executeBatch(b);  
        Test.stopTest();

        List<CampaignMember> campMems = [SELECT Id FROM CampaignMember];
        system.assert(campMems.size() > 0);
        

    }
    
    /**
     * Test that the batch process correctly compiles daily summaries
     */
    @isTest 
    static void testSEBatch() {
/*    
        PardotAPIMock mock = new PardotAPIMock();
        mock.reqType = PardotAPIMock.LIST_TYPE;
        Test.setMock(HttpCalloutMock.class, mock);
*/
        List<Library__c> libs = [SELECT Id FROM Library__c WHERE Name != 'Daily Summary'];
        Set<Id> lSet = new Set<Id>();
        for (Library__c l : libs) {
            lSet.add(l.Id);
        }

        Test.startTest();
        PortalAddCampaignSEMembersBatch b = new PortalAddCampaignSEMembersBatch();
        Id batchId = Database.executeBatch(b);  
        Test.stopTest();

        List<CampaignMember> campMems = [SELECT Id FROM CampaignMember];
        system.assert(campMems.size() > 0);        
    }            
}