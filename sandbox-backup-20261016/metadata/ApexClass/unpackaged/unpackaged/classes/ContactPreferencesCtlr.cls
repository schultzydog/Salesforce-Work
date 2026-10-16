public without sharing class ContactPreferencesCtlr {
    
    public Contact contact {get;set;}
    
    public ContactPreferencesCtlr(ApexPages.StandardController stdController) {
        this.contact = (Contact)stdController.getRecord();
    }
    
    @AuraEnabled
    public static List<RootWrapper> saveApex(String key, String libs, Boolean isCommunity){
        
        System.debug(libs);
        
        List<ContactPreferencesCtlr.LibraryWrapper> lWraps = (List<ContactPreferencesCtlr.LibraryWrapper>) JSON.deserialize(libs ,List<ContactPreferencesCtlr.LibraryWrapper>.class);
        
        List<Contact_Preferences__c> cPrefsToInsert = new List<Contact_Preferences__c>();
        List<Contact_Preferences__c> cPrefsToUpdate = new List<Contact_Preferences__c>();
        List<Contact_Preferences__c> cPrefsToDelete = new List<Contact_Preferences__c>();
        
        for (ContactPreferencesCtlr.LibraryWrapper lw : lWraps){
            
            if (lw.state == 'Contact' && lw.contactPrefId != null){
                
                if (lw.ind != lw.orig_ind || lw.daily != lw.orig_daily) {
                    if (lw.ind || lw.daily){
                        Contact_Preferences__c cp = new Contact_Preferences__c();
                        cp.Id = lw.contactPrefId;
                        cp.Summary_Emails__c = lw.daily;
                        cp.Individual_Emails__c = lw.ind;
                        cp.Edited_by_Client__c = true;
                        cPrefsToUpdate.add(cp);
                    } else {
                        Contact_Preferences__c cp = new Contact_Preferences__c();
                        cp.Id = lw.contactPrefId;
                        cPrefsToDelete.add(cp);
                    }
                }
                else if (lw.ind == lw.orig_ind && 
                         lw.daily == lw.orig_daily && 
                         lw.ind == false && 
                         lw.daily == false){
                    
                    Contact_Preferences__c cp = new Contact_Preferences__c();
                    cp.Id = lw.contactPrefId;
                    cPrefsToDelete.add(cp);
                    
                }
                
            } else if (lw.state == 'Account' && lw.accountPrefId != null){
                
                if (lw.ind || lw.daily){
                    Contact_Preferences__c cp = new Contact_Preferences__c();
                    cp.Contact__c = lw.contactId;
                    cp.Account_Preferences__c = lw.accountPrefId;
                    cp.Summary_Emails__c = lw.daily;
                    cp.Individual_Emails__c = lw.ind;
                    cp.Edited_by_Client__c = true;
                    cPrefsToInsert.add(cp);
                }
                
            }
            
        }
        
        insert cPrefsToInsert;
        update cPrefsToUpdate;
        delete cPrefsToDelete;
        
        if (lWraps.size() > 0 && (cPrefsToInsert.size() > 0 || cPrefsToUpdate.size() > 0 || cPrefsToDelete.size() > 0 ) ){
            
            if (isCommunity){
                Contact con = new Contact();
                con.Id = lWraps[0].contactId;
                con.Contact_Preferences_Edited_by_Contact__c = true;
                update con;
            }
            
        }
        
        return getLibraries(key, isCommunity, false);
    }
    
    @AuraEnabled
    public static List<RootWrapper> getLibraries(String key, Boolean isCommunity, Boolean updateVisits){
        
        User u = [SELECT Id, Name, Use_Scrollbars_on_Contact_Pref_Page__c, Profile.UserLicense.Name FROM User WHERE Id =: UserInfo.getUserId()];
        Boolean scroll = u.Use_Scrollbars_on_Contact_Pref_Page__c;
        
        List<Contact> cons = [SELECT Id, FirstName, LastName, Name, Email, Other_Email__c, Third_Email__c, AccountId, Account.Name, 
                                Account.Owner.Email, Account.Owner.Name, Contact_Type__c, Press_User__c,
                                Contact_Preferences_Page_Visits__c, Contact_Preferences_Edited_by_Contact__c, Contact_Preferences_Date_of_Last_Visit__c, Status__c
                                FROM Contact WHERE (Crypto_Key__c =: key OR Id =: key) AND Crypto_Key__c != NULL];
        Contact con = new Contact();
        if (cons.size() > 0) {
            System.debug('Found Contact: ' + con);
            
            con = cons[0];
            
            if (isCommunity && updateVisits){
                if (con.Contact_Preferences_Page_Visits__c == null){
                    con.Contact_Preferences_Page_Visits__c = 1; 
                } else {
                    con.Contact_Preferences_Page_Visits__c = con.Contact_Preferences_Page_Visits__c + 1;
                }
                con.Contact_Preferences_Date_of_Last_Visit__c = DateTime.now();
                update con;
            }
            
        } else {
            System.debug('No Contact');
        }
        
        System.debug('con: ' + con);
        List<egX_Daily_Blueprint_w_o_Conference_Call__mdt> confCallAccounts = [SELECT Id, Account_Id__c FROM egX_Daily_Blueprint_w_o_Conference_Call__mdt];
        Set<Id> confCallAccountIds = new Set<Id>();
        for (egX_Daily_Blueprint_w_o_Conference_Call__mdt mdt: confCallAccounts){
            confCallAccountIds.add(mdt.Account_Id__c);
        }
        
        Map<Id, Library__c> rootLibMap = new Map<Id, Library__c>([SELECT ID, Name, Sort_Order__c, No_Summary_Emails_Option__c 
            FROM Library__c WHERE RecordType.DeveloperName = 'DistributionListCategory' AND Active__c = TRUE
             AND Hide_from_Contact_Preferences_pages__c = FALSE ORDER BY Sort_Order__c ASC NULLS LAST, Name ASC]);
        List<Library__c> libs = new List<Library__c>();
        
        //List<Library__c> egupdate = [SELECT ID, Name FROM Library__c WHERE Name = 'EG Update' AND Active__c = TRUE];
        
        Set<Id> libIds = new Set<Id>();
        
        //if (egupdate.size() > 0){
        //  libIds.add(egupdate[0].Id);
        //  libs.add(egupdate[0]);
        //}
        
        List<Library__c> childLibs = [SELECT ID, Name, No_Summary_Emails_Option__c, Macro__c, Macro_EMs_T1__c, Macro_EMs_T2__c, DM__c, 
            MSCI_EM__c, MSCI_FM__c, Asia__c, Commodities__c, DM_Major_EM__c, Major_EM__c, Eurasia_Group_coverage_but_not_in_MSCI__c, Starter__c, Distribution_List_SubCategory__c, 
            Distribution_List_SubCategory__r.Distribution_List_Category__c, US_China_Tech__c, Exclusive_List__c, Geotech__c, Geostrategy__c FROM Library__c 
            WHERE Hide_from_Contact_Preferences_pages__c = FALSE AND RecordType.DeveloperName = 'DistributionList' AND (Active__c = TRUE 
            AND Distribution_List_SubCategory__r.Active__c = TRUE AND Distribution_List_SubCategory__r.Distribution_List_Category__r.Active__c = TRUE) 
            AND Distribution_List_SubCategory__r.Distribution_List_Category__c in: rootLibMap.keySet() AND Name != 'MEDIA (FOR EG BUSINESS LINE)' ORDER BY Name ASC];
        
        Map<Id, List<Library__c>> libMap = new Map<Id, List<Library__c>>();
        for (Library__c child : childLibs){
            
            if (child.Distribution_List_SubCategory__c != null) {
                if (libMap.containsKey(child.Distribution_List_SubCategory__r.Distribution_List_Category__c)){
                    libMap.get(child.Distribution_List_SubCategory__r.Distribution_List_Category__c).add(child);
                } else {
                    libMap.put(child.Distribution_List_SubCategory__r.Distribution_List_Category__c, new List<Library__c>{child});
                }
            }
            
        }
        
        for (Library__c root : rootLibMap.values()){
            
            if (libMap.containsKey(root.Id)){
                for (Library__c l : libMap.get(root.Id)){
                    libIds.add(l.Id);
                    libs.add(l);
                }
            }
            
        }
        
        List<Account_Preferences__c> acctPrefs = [SELECT Id, Library__c FROM Account_Preferences__c WHERE Account__c =: con.AccountId AND Library__c in: libIds];
        
        System.debug('acctprefs: ' + acctPrefs);
        
        Map<Id, Account_Preferences__c> acctPrefMap = new Map<Id, Account_Preferences__c>();
        Set<Id> acctPrefIds = new Set<Id>();
        for (Account_Preferences__c ap: acctPrefs) {
            
            acctPrefIds.add(ap.Id);
            acctPrefMap.put(ap.Library__c, ap);
            
        }
        
        List<Contact_Preferences__c> conPrefs = [SELECT Id, Contact__c, Account_Preferences__c, Summary_Emails__c, Individual_Emails__c, Library__c
                                                 FROM Contact_Preferences__c WHERE Contact__c =: con.Id AND Account_Preferences__c in: acctPrefIds];
        
        Map<Id, Contact_Preferences__c> conPrefMap = new Map<Id, Contact_Preferences__c>();
        for (Contact_Preferences__c cp: conPrefs) {
            
            conPrefMap.put(cp.Library__c, cp);
            
        }
        
        List<RootWrapper> rWraps = new List<RootWrapper>();
        
        /*
if (egupdate.size() > 0){

RootWrapper rWrap1 = new RootWrapper();
Library__c l = new Library__c();
//l.Id = 'topitemsid';
l.Name = 'Top Items';
rWrap1.root = l;
rWrap1.email = con.Account.Owner.Email;

List<LibraryWrapper> ls = new List<LibraryWrapper>();
rWrap1.libs = ls;
LibraryWrapper lWrap1 = new LibraryWrapper();
lWrap1.lib = egupdate[0];
if (conPrefMap.containsKey(egupdate[0].Id)){
lWrap1.state = 'Contact';
Contact_Preferences__c cp = conPrefMap.get(egupdate[0].Id);
lWrap1.ind = cp.Individual_Emails__c;
lWrap1.daily = cp.Summary_Emails__c;
lWrap1.orig_ind = cp.Individual_Emails__c;
lWrap1.orig_daily = cp.Summary_Emails__c;

lWrap1.contactPrefId = cp.Id;
lWrap1.contactId = con.Id;
} else if (acctPrefMap.containsKey(egupdate[0].Id)) {
Account_Preferences__c ap = acctPrefMap.get(egupdate[0].Id);
lWrap1.state = 'Account';
lWrap1.accountPrefId =ap .Id;
lWrap1.contactId = con.Id;
lWrap1.ind = false;
lWrap1.daily = false;
lWrap1.orig_ind = false;
lWrap1.orig_daily = false;
} else {
lWrap1.state = 'N/A';
}


rWrap1.libs.add(lWrap1);
rWraps.add(rWrap1);
}
*/
        
        for (Library__c root : rootLibMap.values()){
            
            RootWrapper rWrap = new RootWrapper();
            rWrap.root = root;
            rWrap.accountOwnerEmail = con.Account.Owner.Email;
            rWrap.contactEmail1 = con.Email;
            rWrap.contactEmail2 = con.Other_Email__c;
            rWrap.contactEmail3 = con.Third_Email__c;
            rWrap.ownerName = con.Account.Owner.Name;
            rWrap.isRobot = (con.Contact_Type__c == 'Research Robot');
            rWrap.isPress = con.Press_User__c;
            rWrap.firstname = con.FirstName;
            rWrap.lastname = con.LastName;
            rWrap.scroll = scroll;
            rWrap.enabled = (con.Status__c == 'Enabled');
            rWrap.isLicenseSalesforce = (u.Profile.UserLicense.Name == 'Salesforce');
            
            rWrap.libs = new List<LibraryWrapper>();
            
            rWrap.indState = 'None';
            rWrap.dailyState = 'None';
            
            Boolean indAll = true;
            Boolean indSome = false;
            Boolean dailyAll = true;
            Boolean dailySome = false;
            
            Boolean disabled = true;
            
            if (libMap.containsKey(root.Id)){
                for (Library__c lib : libMap.get(root.Id)){
                    if (lib.Name != 'EG Exclusive' || (lib.Name == 'EG Exclusive' && con.Account.Name == 'Eurasia Group')){
                        LibraryWrapper lWrap = new LibraryWrapper();
                        lWrap.lib = lib;
                        lWrap.contactId = con.Id;
                        
                        if (conPrefMap.containsKey(lib.Id)){
                            lWrap.state = 'Contact';
                            Contact_Preferences__c cp = conPrefMap.get(lib.Id);
                            lWrap.ind = cp.Individual_Emails__c;
                            lWrap.daily = cp.Summary_Emails__c;
                            lWrap.orig_ind = cp.Individual_Emails__c;
                            lWrap.orig_daily = cp.Summary_Emails__c;
                            
                            lWrap.contactPrefId = cp.Id;
                            lWrap.contactId = con.Id;
                            disabled = false;
                            
                            if (cp.Individual_Emails__c) {
                                indSome = true;
                            } else {
                                indAll = false;
                            }
                            if (cp.Summary_Emails__c) {
                                dailySome = true;
                            } else {
                                dailyAll = false;
                            }
                            
                            
                        } else if (acctPrefMap.containsKey(lib.Id)) {
                            Account_Preferences__c ap = acctPrefMap.get(lib.Id);
                            lWrap.state = 'Account';
                            lWrap.accountPrefId =ap .Id;
                            lWrap.contactId = con.Id;
                            lWrap.ind = false;
                            lWrap.daily = false;
                            lWrap.orig_ind = false;
                            lWrap.orig_daily = false;
                            disabled = false;
                            
                            indAll = false;
                            dailyAll = false;
                            
                        } else {
                            lWrap.state = 'N/A';
                            
                            indAll = false;
                            dailyAll = false;
                        }
                        
                        if (lWrap.lib.name == 'zJapan ONLY (DO NOT USE)' || lWrap.lib.name == 'Japan ONLY (DO NOT USE)' ){
                            lWrap.lib.name = '日本クライアント限定サービス';
                        }
                        
                        if (!(!isCommunity && lWrap.state == 'N/A')) {
                            if (!isCommunity || !(lWrap.lib.Name == 'egX Daily Blueprint w/o Conference Call' && !confCallAccountIds.contains(con.AccountId))){
                                rWrap.libs.add(lWrap);
                            }
                        }
                    }
                }
                rWrap.disabled = disabled;
                
                if (rWrap.root.name == 'zJapan ONLY (DO NOT USE)' || rWrap.root.name == 'Japan ONLY (DO NOT USE)' ){
                    rWrap.root.name = '日本クライアント限定サービス';
                }
            }
            
            if (indAll){
                rWrap.indState = 'All';
            } else if (indSome){
                rWrap.indState = 'Some';
            }
            if (dailyAll){
                rWrap.dailyState = 'All';
            } else if (dailySome){
                rWrap.dailyState = 'Some';
            }
            
            
            if (rWrap.libs.size() > 0)
                rWraps.add(rWrap);
        }
        
        List<RootWrapper> returnList = new List<RootWrapper>();
        
        //Make "Publications" Library first in list
        //for (RootWrapper rw : rWraps) {
        //    if (rw.root.Name == 'Publications'){
        //        returnList.add(rw);
        //    }
        //}
        for (RootWrapper rw : rWraps) {
            //if (rw.root.Name != 'Publications'){
            if (rw.root.Name != '日本クライアント限定サービス'){
                returnList.add(rw);
            }
        }
        //Make Japan Library last in list
        for (RootWrapper rw : rWraps) {
            if (rw.root.Name == '日本クライアント限定サービス'){
                returnList.add(rw);
            }
        }
                
        System.debug('returning');
        System.debug(returnList);
        
        return returnList;
        
    }
    
    public class RootWrapper {
        
        @AuraEnabled
        public Library__c root {get;set;}
        @AuraEnabled
        public String ownerName {get;set;}
        @AuraEnabled
        public String accountOwnerEmail {get;set;}
        @AuraEnabled
        public String contactEmail1 {get;set;}
        @AuraEnabled
        public String contactEmail2 {get;set;}
        @AuraEnabled
        public String contactEmail3 {get;set;}
        @AuraEnabled
        public Boolean isRobot {get;set;}
        @AuraEnabled
        public Boolean isPress {get;set;}
        @AuraEnabled
        public String indState {get;set;}
        @AuraEnabled
        public String dailyState {get;set;}
        @AuraEnabled
        public String firstname {get;set;}
        @AuraEnabled
        public String lastname {get;set;}
        @AuraEnabled
        public Boolean scroll {get;set;}
        @AuraEnabled
        public Boolean disabled {get;set;}
        @AuraEnabled
        public Boolean enabled {get;set;}
        @AuraEnabled
        public Boolean isLicenseSalesforce {get;set;}
        
        @AuraEnabled
        public List<LibraryWrapper> libs {get;set;}
        
        public RootWrapper(){
            disabled = false;
        }
        
    }
    
    public class LibraryWrapper {
        
        @AuraEnabled
        public Library__c lib {get;set;}
        @AuraEnabled
        public String state {get;set;}
        
        @AuraEnabled
        public Boolean ind {get;set;}
        @AuraEnabled
        public Boolean daily {get;set;}
        @AuraEnabled
        public Boolean orig_ind {get;set;}
        @AuraEnabled
        public Boolean orig_daily {get;set;}
        
        @AuraEnabled
        public String contactId {get;set;}
        @AuraEnabled
        public String accountPrefId {get;set;}
        @AuraEnabled
        public String contactPrefId {get;set;}
        
        public LibraryWrapper(){
            
        }
        
    }
}