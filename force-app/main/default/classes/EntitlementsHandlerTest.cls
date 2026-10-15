/**
 * Class containing tests for EntitlementsHandler class
 */
@isTest
private class EntitlementsHandlerTest {

    @testSetup
    static void setup() {

        Account a = new Account(Name = 'Test Account',  Conference_Call_Access__c=TRUE, Portal_Access__c=TRUE);
        insert a;
        Opportunity o = new Opportunity(Name = 'Test opp', StageName = 'Prospect', AccountId = a.Id, CloseDate= Date.today());
        insert o;
        a.Status_Enable_Disable__c = 'Enabled';
        update a;
        

        Contact c = new Contact(LastName = 'Contact', FirstName = 'Test', AccountId = a.Id, Email = 'test@test.com', 
                                Status__c = 'Enabled', MailingCity = 'Test',Worldflow_Portal_Access__c=TRUE);
        insert c;
    }

    /**
     * Tests that contact preference insertion updates campaigns correctly and writes to portal
     */
    @isTest 
    static void testCPrefInsert() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Library__c l = new Library__c(Name = 'Test Library');
        insert l;
        Account_Preferences__c aPref = new Account_Preferences__c(Account__c = a.Id, Library__c = l.Id);
        insert aPref;

        Contact_Preferences__c cPref = new Contact_Preferences__c(Account_Preferences__c = aPref.Id, Contact__c = c.Id, Individual_Emails__c = true,
                                                                    Summary_Emails__c = true);
        Test.startTest();
        insert cPref;
        Test.stopTest();


        Campaign cmpgn = [SELECT Id, Tag__c FROM Campaign WHERE Tag__c = :l.Id LIMIT 1];
        List<CampaignMember> mbrList = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE CampaignId = :cmpgn.Id];

        System.assertEquals(1, mbrList.size());
        System.assertEquals(c.Id, mbrList.get(0).ContactId);
    }
    
    /**
     * Tests that contact preference deletion removes contact from correct campaigns and writes to portal
     */
    @isTest 
    static void testCPrefDelete() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Library__c l = new Library__c(Name = 'Test Library');
        insert l;
        Account_Preferences__c aPref = new Account_Preferences__c(Account__c = a.Id, Library__c = l.Id);
        insert aPref;
        Contact_Preferences__c cPref = new Contact_Preferences__c(Account_Preferences__c = aPref.Id, Contact__c = c.Id);
        insert cPref;

        Test.startTest();
        delete cPref;
        Test.stopTest();

        Campaign cmpgn = [SELECT Id, Tag__c FROM Campaign WHERE Tag__c = :l.Id LIMIT 1];
        List<CampaignMember> mbrList = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE CampaignId = :cmpgn.Id];

        System.assertEquals(0, mbrList.size());
    }

    /**
     * Tests that inserting account entitlements writes updates to portal
     */
    @isTest
    static void testAPrefInsert() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        Library__c l = new Library__c(Name = 'Test Library');
        insert l;

        Account_Preferences__c aPref = new Account_Preferences__c(Account__c = a.Id, Library__c = l.Id);
        
        Test.startTest();
        insert aPref;
        Test.stopTest();

    }

    /**
     * Tests that deleting account entitlements writes updates to portal
     */
    @isTest
    static void testAPrefDelete() {
        Account a = [SELECT Id FROM Account LIMIT 1];
        Library__c l = new Library__c(Name = 'Test Library');
        insert l;

        Account_Preferences__c aPref = new Account_Preferences__c(Account__c = a.Id, Library__c = l.Id);
        insert aPref;

        Test.startTest();
        delete aPref;
        Test.stopTest();

        //System.assertNotEquals(null, mock.writtenResponse);
        //System.assert(mock.writtenResponse.contains('{"' + l.Id + '":' + 'false}'));
    }

    /**
     * Tests that new library creation also creates corresponding campaigns
     */ 
    @isTest
    static void testNewLibrary() {
        Library__c l = new Library__c(Name = 'Test Library');

        Test.startTest();
        insert l;
        Test.stopTest();

        List<Campaign> cList = [SELECT Id, Name, Tag__c FROM Campaign];
        System.assertEquals(2, cList.size());

        System.assert(cList[0].Name.contains('Test Library'));
        System.assertEquals(l.Id, cList[0].Tag__c);
        System.assertEquals(l.Id, cList[1].Tag__c);
    }    
}