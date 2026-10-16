@isTest
private class ClientPortal_CompanyReferral_Ctlr_Tests {

    static testmethod void testCompanyReferralForm(){
        Account a = new Account(Name='Test Account');
        insert a;
        
        a = [SELECT Id, Name, Record_Locator__c FROM Account WHERE Id = :a.Id LIMIT 1];

        Contact c = new Contact(LastName='Test Lname',AccountId=a.Id,Email='contact@eg-test.com');
        insert c;

        Test.startTest();
        
		Account company = ClientPortal_CompanyReferral_Ctlr.getCompanyFromReferralKeyApex(a.Record_Locator__c);
        System.assertEquals(a.Id, company.Id);
        
        try{
            ClientPortal_CompanyReferral_Ctlr.getCompanyFromReferralKeyApex('NotAValidRecordLocator');
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
        	State = 'test',
            Country = 'test',
            LeadSource = 'Company Referral',
            Company = a.Name,
            Company_Referral_Account_Id__c = a.Id            
        );

        //personal email domain...
        try{
        	ClientPortal_CompanyReferral_Ctlr.saveLeadApex(leadSubmission);
            System.assert(false, 'Did not get rejected for personal domain when expecting to'); //expecting AuraThrownException above, if we execute this line, the test was not sucessful
        } catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }	
        
        //domain not in existing domains...
        leadSubmission.Email = 'lead@notapproveddomain.com';
        try{
        	ClientPortal_CompanyReferral_Ctlr.saveLeadApex(leadSubmission);
            System.assert(false, 'Did not get rejected for unapproved domain when expecting to'); //expecting AuraThrownException above, if we execute this line, the test was not sucessful
        } catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }	

        //legit insert...
        leadSubmission.Email = 'lead@eg-test.com';
        ClientPortal_CompanyReferral_Ctlr.saveLeadApex(leadSubmission);
		
        List<Lead> savedLeads = [SELECT Id, Email FROM Lead WHERE Email = :leadSubmission.Email];
        System.assertEquals(1, savedLeads.size());
        System.assertEquals('lead@eg-test.com', savedLeads[0].Email);
        
        //reset leadSubmission...
        leadSubmission.Id = null;

        //duplicate contact...
        leadSubmission.Email = 'contact@eg-test.com';
        ClientPortal_CompanyReferral_Ctlr.saveLeadApex(leadSubmission);
        List<Error_Log__c> errorLogs = [SELECT Id, Record_ID__c FROM Error_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        if(errorLogs[0].Record_ID__c!='New Lead') System.assertEquals(c.Id, errorLogs[0].Record_ID__c);
        
        //duplicate lead...
        leadSubmission.Email = 'lead@eg-test.com';
        ClientPortal_CompanyReferral_Ctlr.saveLeadApex(leadSubmission);
        errorLogs = [SELECT Id, Record_ID__c FROM Error_Log__c ORDER BY CreatedDate DESC LIMIT 1];
        //System.assertEquals('00Q', errorLogs[0].Record_ID__c.left(3));
            
        Test.stopTest();
    }

}