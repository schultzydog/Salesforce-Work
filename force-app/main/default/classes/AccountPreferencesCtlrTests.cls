@isTest
public class AccountPreferencesCtlrTests {

    static testmethod void testAcctPrefs(){
        
        Account a1 = new Account(Name='Test Account 1');
        insert a1;
        Account a2 = new Account(Name='Test Account 2');
        insert a2;
        Contact c = new Contact(LastName='Test Lname',AccountId=a1.Id,Email='test@abc.com',Crypto_Key__c='123');
        insert c;
        Contact c2 = new Contact(LastName='Second Contact',AccountId=a2.Id,Email='contact@test.com',Crypto_Key__c='1234');
        insert c2;

        RecordType distributionListRT = [SELECT ID FROM RecordType WHERE sObjectType = 'Library__c' AND DeveloperName = 'DistributionList'];
        RecordType distributionListSubCategoryRT = [SELECT ID FROM RecordType WHERE sObjectType = 'Library__c' AND DeveloperName = 'DistributionListSubCategory'];
        RecordType distributionListCategoryRT = [SELECT ID FROM RecordType WHERE sObjectType = 'Library__c' AND DeveloperName = 'DistributionListCategory'];

        Library__c l1 = new Library__c(Name = 'Test Library 1',RecordTypeId=distributionListCategoryRT.Id,Active__c=TRUE);
        insert l1;
        Library__c l2 = new Library__c(Name = 'Test Library 2',RecordTypeId=distributionListSubCategoryRT.Id,Active__c=TRUE,Distribution_List_Category__c=l1.Id);
        insert l2;
        Library__c l3 = new Library__c(Name = 'Test Library 3',RecordTypeId=distributionListRT.Id,Active__c=TRUE,Distribution_List_SubCategory__c=l2.Id);
        insert l3;
        Library__c l4 = new Library__c(Name = 'Test Library 4',RecordTypeId=distributionListRT.Id,Active__c=TRUE,Distribution_List_SubCategory__c=l2.Id);
        insert l4;
        Library__c l5 = new Library__c(Name = 'Publications',RecordTypeId=distributionListRT.Id,Active__c=TRUE,Distribution_List_SubCategory__c=l2.Id);
        insert l5;
        Account_Preferences__c aPref1 = new Account_Preferences__c(Account__c = a1.Id, Library__c = l3.Id);
        insert aPref1;
        Account_Preferences__c aPref2 = new Account_Preferences__c(Account__c = a1.Id, Library__c = l1.Id);
        insert aPref2;
        Account_Preferences__c aPref3 = new Account_Preferences__c(Account__c = a2.Id, Library__c = l5.Id);
        insert aPref3;
        Account_Preferences__c aPref4 = new Account_Preferences__c(Account__c = a1.Id, Library__c = l4.Id);
        insert aPref4;
        Contact_Preferences__c cPref1 = new Contact_Preferences__c(Account_Preferences__c = aPref1.Id, Contact__c = c.Id);
        insert cPref1;
        //Contact_Preferences__c cPref2 = new Contact_Preferences__c(Account_Preferences__c = aPref2.Id, Contact__c = c.Id);
        //insert cPref2;

        List<AccountPreferencesCtlr.RootWrapper> roots = AccountPreferencesCtlr.getLibraries(a1.id);
        List<AccountPreferencesCtlr.LibraryWrapper> libs = roots[0].libs;

        libs[0].selected = true;

        List<AccountPreferencesCtlr.RootWrapper> roots2 = AccountPreferencesCtlr.saveApex(a1.Id, JSON.serialize(libs));

        Contact_Preferences__c cPref3 = new Contact_Preferences__c(Account_Preferences__c = aPref3.Id, Contact__c = c2.Id);
        insert cPref3;

        List<AccountPreferencesCtlr.RootWrapper> roots3 = AccountPreferencesCtlr.getLibraries(a2.id);
        List<AccountPreferencesCtlr.LibraryWrapper> libs2 = roots3[0].libs;

        libs2[0].selected = true;

        List<AccountPreferencesCtlr.RootWrapper> roots4 = AccountPreferencesCtlr.saveApex(a2.Id, JSON.serialize(libs2));        
    }
    
}