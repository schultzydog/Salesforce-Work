public class AccountPreferencesCtlr {
    
    public Account account {get;set;}
    
    public AccountPreferencesCtlr(ApexPages.StandardController stdController) {
        this.account = (Account)stdController.getRecord();
    }
    
    @AuraEnabled
    public static List<RootWrapper> saveApex(String key, String libs){
        
        List<AccountPreferencesCtlr.LibraryWrapper> lWraps = (List<AccountPreferencesCtlr.LibraryWrapper>) JSON.deserialize(libs ,List<AccountPreferencesCtlr.LibraryWrapper>.class);
        
        List<Account_Preferences__c> aPrefsToInsert = new List<Account_Preferences__c>();
        List<Account_Preferences__c> aPrefsToUpdate = new List<Account_Preferences__c>();
        List<Account_Preferences__c> aPrefsToDelete = new List<Account_Preferences__c>();
        
        for (AccountPreferencesCtlr.LibraryWrapper lw : lWraps){
            
            if (lw.state == 'Account'){
                
                if (lw.selected != lw.orig_selected) {
                    if (lw.selected){
                        Account_Preferences__c ap = new Account_Preferences__c();
                        //ap.Id = lw.accountPrefId;
                        ap.Account__c = lw.accountId;
                        ap.Library__c = lw.lib.Id;
                        aPrefsToInsert.add(ap);
                    } else {
                        Account_Preferences__c ap = new Account_Preferences__c();
                        ap.Id = lw.accountPrefId;
                        aPrefsToDelete.add(ap);
                    }
                }
                
            }
            
        }
        
        insert aPrefsToInsert;
        //update aPrefsToUpdate;
        delete aPrefsToDelete;
        
        return getLibraries(key);
    }
    
    @AuraEnabled
    public static List<RootWrapper> getLibraries(String key){
        
        User u = [SELECT Id, Name, Use_Scrollbars_on_Contact_Pref_Page__c, Profile.UserLicense.Name FROM User WHERE Id =: UserInfo.getUserId()];
        
        List<Account> accs = [SELECT Id, Name, Owner.Email FROM Account WHERE (Id =: key)];
        Account acc = new Account();
        if (accs.size() > 0) acc = accs[0];
        
        List<egX_Daily_Blueprint_w_o_Conference_Call__mdt> exceptionMetadata = [SELECT Id, Account_Id__c, Libary_Id__c FROM egX_Daily_Blueprint_w_o_Conference_Call__mdt];
        Set<String> exceptionAccountIds = new Set<String>();
        Set<String> exceptionLibraryIds = new Set<String>();
        Set<String> exceptionKeys = new Set<String>();
        for (egX_Daily_Blueprint_w_o_Conference_Call__mdt mdt: exceptionMetadata){
            exceptionAccountIds.add(mdt.Account_Id__c);
            exceptionLibraryIds.add(mdt.Libary_Id__c);
            exceptionKeys.add(mdt.Account_Id__c+'|'+mdt.Libary_Id__c);
        }
        Map<Id, Library__c> rootLibMap = new Map<Id, Library__c>([SELECT ID, Name, Sort_Order__c FROM Library__c WHERE RecordType.DeveloperName = 'DistributionListCategory'AND Hide_from_Contact_Preferences_pages__c = FALSE AND Active__c = TRUE ORDER BY Sort_Order__c ASC NULLS LAST, Name ASC]);
        List<Library__c> libs = new List<Library__c>();
        
        Set<Id> libIds = new Set<Id>();
        
        List<Library__c> childLibs = [SELECT ID, Name, DM__c, MSCI_EM__c, Distribution_List_SubCategory__c, Distribution_List_SubCategory__r.Distribution_List_Category__c, Exclusive_List__c FROM Library__c WHERE RecordType.DeveloperName = 'DistributionList' AND Hide_from_Contact_Preferences_pages__c = FALSE AND (Active__c = TRUE AND Distribution_List_SubCategory__r.Active__c = TRUE AND Distribution_List_SubCategory__r.Distribution_List_Category__r.Active__c = TRUE) AND Distribution_List_SubCategory__r.Distribution_List_Category__c in: rootLibMap.keySet() AND Name != 'MEDIA (FOR EG BUSINESS LINE)' ORDER BY Name ASC];
        
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
        
        List<Account_Preferences__c> acctPrefs = [SELECT Id, Library__c FROM Account_Preferences__c WHERE Account__c =: acc.Id AND Library__c in: libIds];
        
        Map<Id, Account_Preferences__c> acctPrefMap = new Map<Id, Account_Preferences__c>();
        Set<Id> acctPrefIds = new Set<Id>();
        for (Account_Preferences__c ap: acctPrefs) {
            
            acctPrefIds.add(ap.Id);
            acctPrefMap.put(ap.Library__c, ap);
            
        }
        
        List<RootWrapper> rWraps = new List<RootWrapper>();
        
        for (Library__c root : rootLibMap.values()){
            
            RootWrapper rWrap = new RootWrapper();
            rWrap.root = root;
            rWrap.email = acc.Owner.Email;
            rWrap.isLicenseSalesforce = (u.Profile.UserLicense.Name == 'Salesforce');
            
            rWrap.libs = new List<LibraryWrapper>();
            
            rWrap.state = 'None';
            
            Boolean all = true;
            Boolean some = false;
            
            Boolean disabled = true;
            
            if (libMap.containsKey(root.Id)){
                for (Library__c lib : libMap.get(root.Id)){
                    
                    LibraryWrapper lWrap = new LibraryWrapper();
                    lWrap.lib = lib;
                    
                    if (!lib.Exclusive_List__c ||
                        (lib.Exclusive_List__c && exceptionKeys.contains(acc.Id+'|'+lib.Id)) ){
                            //if (!(exceptionLibraryIds.contains(lib.Id) && !(exceptionKeys.contains(acc.Id+'|'+lib.Id))) ){    
                            //if (! (lib.Exclusive_List__c && !(exceptionKeys.contains(acc.Id+'|'+lib.Id)) ) ) {
                            //if ((lWrap.lib.Name != 'egX Daily Blueprint w/o Conference Call' || confCallAccountIds.contains(acc.Id))){                        
                            if (acctPrefMap.containsKey(lib.Id)) {
                                Account_Preferences__c ap = acctPrefMap.get(lib.Id);
                                lWrap.state = 'Account';
                                lWrap.accountPrefId =ap .Id;
                                lWrap.accountId = acc.Id;
                                lWrap.selected = true;
                                lWrap.orig_selected = true;
                                disabled = false;
                                
                                some = true;
                            } else {
                                //Account_Preferences__c ap = acctPrefMap.get(lib.Id);
                                lWrap.state = 'Account';
                                //lWrap.accountPrefId =ap .Id;
                                lWrap.accountId = acc.Id;
                                lWrap.selected = false;
                                lWrap.orig_selected = false;
                                disabled = false;
                                
                                all = false;
                            }
                            
                            if (lWrap.lib.name == 'zJapan ONLY (DO NOT USE)' || lWrap.lib.name == 'Japan ONLY (DO NOT USE)' ){
                                lWrap.lib.name = '日本クライアント限定サービス';
                            }
                            
                            rWrap.libs.add(lWrap);
                            //}
                        }
                }
                rWrap.disabled = disabled;
                if (rWrap.root.name == 'zJapan ONLY (DO NOT USE)' || rWrap.root.name == 'Japan ONLY (DO NOT USE)' ){
                    rWrap.root.name = '日本クライアント限定サービス';
                }
            }
            
            if (all){
                rWrap.state = 'All';
            } else if (some){
                rWrap.state = 'Some';
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
        
        return returnList;
        
    }
    
    public class RootWrapper {
        
        @AuraEnabled
        public Library__c root {get;set;}
        @AuraEnabled
        public String email {get;set;}
        @AuraEnabled
        public String state {get;set;}
        @AuraEnabled
        public Boolean disabled {get;set;}
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
        public Boolean selected {get;set;}
        @AuraEnabled
        public Boolean orig_selected {get;set;}
        
        @AuraEnabled
        public String accountId {get;set;}
        @AuraEnabled
        public String accountPrefId {get;set;}
        @AuraEnabled
        public String contactPrefId {get;set;}
        
        public LibraryWrapper(){
            
        }
        
    }
}