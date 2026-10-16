@IsTest
public class ContactPreferencesCtlrTests {

    static testmethod void testContactPreferencesPage(){
 
        Account a1 = new Account(Name='Test Account 1', BillingCity = 'Test', BillingCountry = 'United States');
        insert a1;
        Account a2 = new Account(Name='Test Account 2', BillingCity = 'Test', BillingCountry = 'United States');
        insert a2;
        Account a3 = new Account(Name='Test Account 3', BillingCity = 'Test', BillingCountry = 'United States');
        insert a3;
        Contact c = new Contact(LastName='Test Lname',AccountId=a1.Id,Email='test@abc.com',Crypto_Key__c='123');
        insert c;
        Contact c2 = new Contact(LastName='Second Contact',AccountId=a2.Id,Email='contact@test.com',Crypto_Key__c='1234');
        insert c2;
        Contact c3 = new Contact(LastName='Third Contact',AccountId=a3.Id,Email='contact3@test.com',Crypto_Key__c='12345');
        insert c3;

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
        Account_Preferences__c aPref5 = new Account_Preferences__c(Account__c = a3.Id, Library__c = l4.Id);
        insert aPref5;
        Contact_Preferences__c cPref1 = new Contact_Preferences__c(Account_Preferences__c = aPref1.Id, Contact__c = c.Id);
        insert cPref1;
        Contact_Preferences__c cPref2 = new Contact_Preferences__c(Account_Preferences__c = aPref5.Id, Contact__c = c3.Id);
        cPref2.Individual_Emails__c = false;
        cPref2.Summary_Emails__c = false;
        insert cPref2;

        List<ContactPreferencesCtlr.RootWrapper> roots = ContactPreferencesCtlr.getLibraries('123', false, false);
        List<ContactPreferencesCtlr.LibraryWrapper> libs = roots[0].libs;

        libs[0].ind = true;
        libs[0].daily = true;

        List<ContactPreferencesCtlr.RootWrapper> roots2 = ContactPreferencesCtlr.saveApex('123', JSON.serialize(libs),false);

        Contact_Preferences__c cPref3 = new Contact_Preferences__c(Account_Preferences__c = aPref3.Id, Contact__c = c2.Id);
        insert cPref3;

        List<ContactPreferencesCtlr.RootWrapper> roots3 = ContactPreferencesCtlr.getLibraries('1234', false,false);
        List<ContactPreferencesCtlr.LibraryWrapper> libs2 = roots3[0].libs;

        libs2[0].ind = true;
        libs2[0].daily = true;

        List<ContactPreferencesCtlr.RootWrapper> roots4 = ContactPreferencesCtlr.saveApex('1234', JSON.serialize(libs2),false);

        List<ContactPreferencesCtlr.RootWrapper> roots5 = ContactPreferencesCtlr.getLibraries('12345', false,false);
        List<ContactPreferencesCtlr.LibraryWrapper> libs3 = roots5[0].libs;
        List<ContactPreferencesCtlr.RootWrapper> roots6 = ContactPreferencesCtlr.saveApex('12345', JSON.serialize(libs3),false);
        
        List<Contact_Preferences__c> zeroPrefs = [SELECT ID FROM Contact_Preferences__c WHERE Id =: cPref2.Id];
        System.Assert(zeroPrefs.size() == 0);
        
    }

}