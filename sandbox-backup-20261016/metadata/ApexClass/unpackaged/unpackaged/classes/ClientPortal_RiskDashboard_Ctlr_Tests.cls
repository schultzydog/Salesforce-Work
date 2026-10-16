@isTest
private class ClientPortal_RiskDashboard_Ctlr_Tests {


    static testMethod void testClientPortalRiskDashboardCtlr() {
    
        List<Account> accts = new List<Account>();
        
        Account acct1 = new Account(Name='Test1', Status_Enable_Disable__c='Enabled', Count_of_Enabled_Contacts__c = 10, Conference_Call_Access__c=true);
        accts.add(acct1);
        Account acct2 = new Account(Name='Test2', Status_Enable_Disable__c='Enabled', Count_of_Enabled_Contacts__c = 20, Conference_Call_Access__c=true);   
        accts.add(acct2);     
        insert accts;
        
        Contact TestContact = new Contact(AccountId = acct1.id,
                                           LastName = 'TestLastName1',
                                           Title = 'TestTitle',
                                           Status__c = 'Enabled',
                                           Email = '23rsd98f73@3fad.com');
        insert TestContact;
       
        
        Id dlId = [SELECT Id FROM RecordType WHERE DeveloperName = 'DistributionList' LIMIT 1].Id;
        Id dlscId = [SELECT Id FROM RecordType WHERE DeveloperName = 'DistributionListSubCategory' LIMIT 1].Id;
        Id dlcId = [SELECT Id FROM RecordType WHERE DeveloperName = 'DistributionListCategory' LIMIT 1].Id;
        
        //Create Distribution List Categories 
        List<Library__c> libDLCInserts = new List<Library__c>(); 
        
        Library__c asia = new Library__c(RecordTypeId = dlcID, Name='Asia');
        libDLCInserts.add(asia);
        Library__c data = new Library__c(RecordTypeId = dlcID, Name='Data & Analytics');
        libDLCInserts.add(data );
        Library__c ecr = new Library__c(RecordTypeId = dlcID, Name='Energy, Climate & Resources');
        libDLCInserts.add(ecr);
        Library__c eurasia = new Library__c(RecordTypeId = dlcID, Name='Eurasia');
        libDLCInserts.add(eurasia);
        Library__c europe = new Library__c(RecordTypeId = dlcID, Name='Europe');
        libDLCInserts.add(europe);
        Library__c geotech = new Library__c(RecordTypeId = dlcID, Name='Geo-Technology');
        libDLCInserts.add(geotech);
        Library__c globalmacro = new Library__c(RecordTypeId = dlcID, Name='Global Macro');
        libDLCInserts.add(globalmacro);
        Library__c globalstrategy = new Library__c(RecordTypeId = dlcID, Name='Global Strategy');
        libDLCInserts.add(globalstrategy);
        Library__c healthcare = new Library__c(RecordTypeId = dlcID, Name='Healthcare');
        libDLCInserts.add(healthcare);
        Library__c japan = new Library__c(RecordTypeId = dlcID, Name='Japan');
        libDLCInserts.add(japan);
        Library__c latam = new Library__c(RecordTypeId = dlcID, Name='Latin America');
        libDLCInserts.add(latam);
        Library__c mena = new Library__c(RecordTypeId = dlcID, Name='Middle East/North Africa');
        libDLCInserts.add(mena);
        Library__c northamerica = new Library__c(RecordTypeId = dlcID, Name='North America');
        libDLCInserts.add(northamerica);
        Library__c ssafrica = new Library__c(RecordTypeId = dlcID, Name='Sub-Saharan Africa');
        libDLCInserts.add(ssafrica);
        
        insert libDLCInserts;
        
        //create distribution subcategory library records
        List<Library__c> libDLSCInserts = new List<Library__c>();
        for (Library__c lib : libDLCInserts) {
            Library__c dlsc = new Library__c(RecordTypeId = dlscID, Distribution_List_Category__c = lib.Id, Name = lib.Name);
            libDLSCInserts.add(dlsc);
        }     
        insert libDLSCInserts;
        
        //create distribution list library records
        List<Library__c> libDLInserts = new List<Library__c>();
        for (Library__c lib : libDLSCInserts) {
            Library__c dl = new Library__c(RecordTypeId = dlID, Distribution_List_SubCategory__c = lib.Id, Name = lib.Name);
            libDLInserts.add(dl);
        }     
        insert libDLInserts;
        
        //create account pref records 
        List<Account_Preferences__c> apInserts = new List<Account_Preferences__c>();      
        for (Library__c lib : libDLInserts) {
            Account_Preferences__c ap = new Account_Preferences__c(Account__c = acct1.Id, Research__c = true, Client_Portal_Political_Risk_Dashboard__c  = true, Count_of_Active_Contact_Prefs__c = 1,Library__c =lib.id);
            apInserts.add(ap);
        }
        
        insert apInserts;
        
        
        Political_Risk_Analysis__c pra = new Political_Risk_Analysis__c(Published_Date__c=Date.newInstance(2022, 4, 1));
        insert pra;
        Regional_Analysis__c ra = new Regional_Analysis__c(Political_Risk_Analysis__c=pra.Id, Region__c=asia.Id);
        insert ra;

        /*
        Account_Preferences_by_Month__c  accountPreferencesByMonth = new Account_Preferences_by_Month__c ();
        accountPreferencesByMonth.Name = acct.Name + '-' + year + '-' + String.valueOf(month).leftPad(2, '0');
        accountPreferencesByMonth.External_Id__c = acct.Id + '-' + year + '-' + String.valueOf(month).leftPad(2, '0');
        accountPreferencesByMonth.Account__c = acct.Id;
        accountPreferencesByMonth.Year__c = String.valueOf(year);
        accountPreferencesByMonth.Month__c = month;
        insert accountPreferencesByMonth;
        */

        Test.startTest();     
        
            List<Political_Risk_Analysis__c> pras = ClientPortal_RiskDashboard_Ctlr.getPoliticalRiskAnalysesApex();
            ClientPortal_RiskDashboard_Ctlr.getHighriskSignpostsApex(pras[0].Id);
            ClientPortal_RiskDashboard_Ctlr.getPoliticalRiskAnalysisApex(pras[0].Id);
            List<Regional_Analysis__c> ras = ClientPortal_RiskDashboard_Ctlr.getSubscribedRegionalAnalysesApex(pras[0].Id);
            ClientPortal_RiskDashboard_Ctlr.getRegionalAnalysisApex(ras[0].Id);

            
        Test.stopTest();
        
        //make some assertions on Account_Preferences_by_Month__c
       
    }


}