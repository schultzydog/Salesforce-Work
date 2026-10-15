global class RipplingEmailHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        //system.debug('### email.PlainTextBody = '+ email.PlainTextBody);
        //system.debug('### email.htmlBody= '+ email.htmlBody);
        system.debug('### email.Subject= '+ email.Subject);
        
        String firstName;
        String lastName;
        String emailAddress;
        String title;
        String department;
        String accountId = [SELECT Id from Account WHERE Name = 'Eurasia Group' LIMIT 1].Id;

        if(email.Subject != 'Subject: Rippling - SF New Contact') return result;
        
        //EXTRACT First Name
        String firstNameRegEx = 'First Name: (.*)\\n';
        Matcher pmFirstName = Pattern.compile(firstNameRegEx).matcher(email.htmlBody);
        pmFirstName.matches();
        while (pmFirstName.find()) {
            firstName = pmFirstName.group(1);
            system.debug('### firstName= ' +firstName);
        }
    
        //EXTRACT Last Name
        String lastNameRegEx = 'Last Name: (.*)\\n';
        Matcher pmLastName = Pattern.compile(lastNameRegEx).matcher(email.htmlBody);
        pmLastName.matches();
        while (pmLastName.find()) {
            lastName = pmLastName.group(1);
            system.debug('### lastName= ' +lastName);
        }

        //EXTRACT Email
        String emailRegEx = 'Email: (.*)\\n';
        Matcher pmEmail = Pattern.compile(emailRegEx).matcher(email.htmlBody);
        pmEmail.matches();
        while (pmEmail.find()) {
            emailAddress = pmEmail.group(1);
            system.debug('### emailAddress = ' +emailAddress);
        }
        
        //EXTRACT Title
        String titleRegEx = 'Title: (.*)\\n';
        Matcher pmTitle = Pattern.compile(titleRegEx).matcher(email.htmlBody);
        pmTitle.matches();
        while (pmTitle.find()) {
            title = pmTitle.group(1);
            system.debug('### title = ' +title );
        }
        
        //EXTRACT Department
        String DepartmentRegEx = 'Department: (.*)\\n';
        Matcher pmDepartment = Pattern.compile(DepartmentRegEx).matcher(email.htmlBody);
        pmDepartment.matches();
        while (pmDepartment.find()) {
            department = pmDepartment.group(1);
            system.debug('### department = ' +department );
        }

        //Check if User exists
        List<User> userCheck = [SELECT Id FROM User WHERE Username =:emailAddress LIMIT 1];

        //Check if Contact exists
        List<Contact> contactCheck = [SELECT Id FROM Contact WHERE Email =:emailaddress LIMIT 1];

        //Create new User
        if (userCheck.size() < 1) {
            //create Alias
            String firstNameLetter = firstName.left(1);
            String lastNameLetters = lastName.left(2);
            String alias = firstNameLetter + lastNameLetters; 
        
            User u = new user();
            u.FirstName = firstName;
            u.LastName = lastName;
            u.Email = emailAddress;
            u.Alias = alias;
            u.Username = emailAddress;
            //u.CommunityNickname = 'test12';
            u.LocaleSidKey = 'en_US';
            u.TimeZoneSidKey = 'America/New_York';
            u.ProfileID = '00e30000001YixE';
            u.LanguageLocaleKey = 'en_US';
            u.EmailEncodingKey = 'UTF-8';
            u.Department = department;
            u.Created_by_Rippling_Email_automation__c = TRUE;
            insert u;
        } else {
            userCheck[0].Rippling_automation_user_exists__c = TRUE;
            update userCheck[0];
        }
        
        //Create new Contact
        if (contactCheck.size() < 1) {
            Contact c = new Contact();
            c.AccountId = accountId;
            c.Email = emailAddress;
            c.FirstName = firstName;
            c.LastName = lastName;
            c.Title = title;
            c.Status__c = 'Enabled';
            c.Worldflow_Email_Access__c = TRUE;
            c.Worldflow_Portal_Access__c = TRUE;
            c.Created_by_Rippling_Email_automation__c = TRUE;
            insert c;
        
            //Subscribe new Contact to all pubs                                                                 
            List<Contact_Preferences__c> cPrefInsert = new List<Contact_Preferences__c>();                                                                                                            
            //for (Account_Preferences__c a : [SELECT Id FROM Account_Preferences__c WHERE Account__c = :accountId]) { 
            //    Contact_Preferences__c cPref = new Contact_Preferences__c(Contact__c = c.Id, Account_Preferences__c = a.Id, Individual_Emails__c = true, Summary_Emails__c = true);
            //    cPrefInsert.add(cPref);
            //}
  
            //system.debug('### cPrefInsert.size() = ' + cPrefInsert.size());
            //insert cPrefInsert;        
        } else {
            contactCheck[0].Rippling_automation_contact_exists__c = TRUE; 
            update contactCheck[0];
        } 
        return result;
    }
}