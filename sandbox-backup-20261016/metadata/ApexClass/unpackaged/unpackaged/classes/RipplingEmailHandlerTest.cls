@isTest
public class RipplingEmailHandlerTest {

    @isTest
    public static void EmailServiceTest() {
        
        // setup controller object
        RipplingEmailHandler emailServiceController = new RipplingEmailHandler();
        
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.subject = 'This is the email subject and is so super unique';
        email.plainTextBody = 'Hello, this a test email body for testing purposes only.';
        email.htmlBody ='First Name: Rippling \n\n Last Name: Tester \n\n Work Email: user@ripplingintegrationtest.com \n\n Title: RipplingTester  \n\n Department: Finance';     
        email.Subject = 'Subject: Rippling - SF New Contact';
        
        List<String> toAddresses = new List<String>();
        toAddresses.add('salesforcesupport@workforce.org');
        email.toAddresses = toAddresses;
        
        List<String> ccAddresses = new List<String>();
        ccAddresses.add('salesforcesupport@workforce.org');
        email.ccAddresses = ccAddresses;
        
        envelope.fromAddress = 'sef@email.com';
        //envelope.toAddress = 'salesforcesupport@workforce.org';
        
        Account a = new Account();
        a.Name = 'Eurasia Group';
        a.Conference_Call_Access__c = TRUE;
        a.Portal_Access__c = TRUE;
        a.Email_Access__c = TRUE;
        insert a;
        
        
        //emailServiceController.handleInboundEmail(email, envelope);

        Messaging.InboundEmailResult result = emailServiceController.handleInboundEmail(email, envelope);
        System.debug( result );
    }
    
}