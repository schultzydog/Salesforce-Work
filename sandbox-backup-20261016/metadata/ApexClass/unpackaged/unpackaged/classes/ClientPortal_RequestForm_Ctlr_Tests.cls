@isTest
private class ClientPortal_RequestForm_Ctlr_Tests {

    static testmethod void testRequestForm(){
        Account a = new Account(Name='Test Account');
        insert a;
        
        a = [SELECT Id, Name, Record_Locator__c FROM Account WHERE Id = :a.Id LIMIT 1];

        Contact c = new Contact(LastName='Test Lname',AccountId=a.Id,Email='contact@eg-test.com');
        insert c;

        Id dlId = [SELECT Id FROM RecordType WHERE DeveloperName = 'DistributionList' LIMIT 1].Id;
        
        //Create Distribution List Categories 
        Library__c library = new Library__c(RecordTypeId=dlId, Name='Crypto Ledger');
        insert library;

        Test.startTest();
        
		Library__c lib = ClientPortal_RequestForm_Ctlr.getPageDataApex(library.Id);
        System.assertEquals(library.Id, lib.Id);
        
        try{
            ClientPortal_RequestForm_Ctlr.getPageDataApex('NotAValidLibraryId');
            System.assert(false, 'Did not get rejected for invalid referral source when expecting to'); //expecting AuraThrownException above, if we execute this line, the test was not sucessful
        } catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage()); //Invalid referral source
        }	
        
        Lead leadSubmission = new Lead(
        	FirstName = 'test',
        	LastName = 'test',
        	Department__c = 'test',
        	Title = 'test',
        	Email = 'lead@gmail.com',
            Country = 'test',
            LeadSource = 'Company Referral'
        );

        //personal email domain...
        try{
        	ClientPortal_RequestForm_Ctlr.saveLeadApex(leadSubmission);
            System.assert(false, 'Did not get rejected for personal domain when expecting to'); //expecting AuraThrownException above, if we execute this line, the test was not sucessful
        } catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }	
        
        //legit insert...
        leadSubmission.Email = 'lead@eg-test.com';
        ClientPortal_RequestForm_Ctlr.saveLeadApex(leadSubmission);
		
        List<Lead> savedLeads = [SELECT Id, Email FROM Lead WHERE Email = :leadSubmission.Email];
        System.assertEquals(0, savedLeads.size());

        leadSubmission.Company = 'Unit Test Company Required';

        ClientPortal_RequestForm_Ctlr.saveLeadApex(leadSubmission);

        savedLeads = [SELECT Id, Email FROM Lead WHERE Email = :leadSubmission.Email];
        System.assertEquals(1, savedLeads.size());
        System.assertEquals('lead@eg-test.com', savedLeads[0].Email);
        
        //reset leadSubmission...
        leadSubmission.Id = null;
        
        leadSubmission.Email = 'contact@eg-test.com';
        ClientPortal_RequestForm_Ctlr.saveLeadApex(leadSubmission);

        Test.stopTest();
    }

}