/**
 *  Test class for Content document Link Trigger
 */
@isTest
private class ContentDocumentLinkTriggerHandlerTest {
     @testSetup
    private static void setupData(){
        Account acct1 = new Account(Name='Test1', Conference_Call_Access__c = TRUE);
        insert acct1;
        Opportunity opp1 = new Opportunity(Name='test opp1',
                                            AccountId = acct1.Id,
                                            StageName='0% - Prospect',
                                            Amount = 2500, 
                                            CloseDate=system.today(), 
                                            Business_Line__c = 'GZERO',
                                            Contract_Start_Date__c = System.Today().addDays(-90),
                                            Contract_End_Date__c = System.Today().addDays(+90),
                                            Multi_year_Contract__c = 'No'); 
        insert opp1;
    }
    
    @isTest
    private static void testTrigger(){
        
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        ContentVersion contentVersion_1 = new ContentVersion(
            Title='Header_Picture1', 
            PathOnClient ='/Header_Picture1.jpg',
            VersionData = bodyBlob, 
            origin = 'H'
        );
        insert contentVersion_1;
        contentVersion_1 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
       
        List<Opportunity> opps =[SELECT ID , AccountId FROM Opportunity];
        List<ContentDocumentLink> contentlinks = new List<ContentDocumentLink>();
        for(Opportunity opp : opps){
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = opp.id;
            contentlink.contentdocumentid = contentVersion_1.contentdocumentid;
            contentlink.ShareType = 'V';
            contentlinks.add(contentlink);
        }
        Test.startTest();
        insert contentlinks;
        List<ContentDocumentLink> cdls = [SELECT ID FROM ContentDocumentLink Where LinkedEntityId=:opps[0].AccountId
                                                AND contentdocumentid =: contentVersion_1.contentdocumentid];
        system.assertEquals(1, cdls.size());
       Test.stopTest();
        
    }

}