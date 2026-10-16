/*
 * Test Ckass for egGprInterfaceController
 */
@isTest
private class egGprInterfaceControllerTest {

     static testMethod void myTest() {
        Id rtId = [SELECT Id FROM RecordType WHERE DeveloperName = 'DistributionList' LIMIT 1].Id;
        system.debug('### rtId = ' + rtId);
         
        Library__c LibraryDistributionList = new Library__c(RecordTypeId = rtId, Name='EG Update');
        insert LibraryDistributionList;
         
         egGprInterfaceController.getOptions();
         Country_Rating__c gpri = egGprInterfaceController.getCountryRating(Date.today().month(), Date.today().year(),LibraryDistributionList.Id);
         gpri.Status__c = 'Draft';
        egGprInterfaceController.saveCountryRating(gpri);
        
     }
}