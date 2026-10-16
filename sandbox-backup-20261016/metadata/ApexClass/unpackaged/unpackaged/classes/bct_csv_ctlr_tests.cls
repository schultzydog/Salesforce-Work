@isTest
private with sharing class bct_csv_ctlr_tests {

    static testMethod void testExportCsv() {

        
        insert new BCT__c(Publish__c=true);

        Test.startTest();  

        Test.setCurrentPageReference(new PageReference('Page.bct_csv_tests'));
        System.currentPageReference().getParameters().put('table', '1');
        System.currentPageReference().getParameters().put('lang', 'pt-br');

        bct_csv_ctlr ctrl = new bct_csv_ctlr();

        Test.stopTest();
    

    }

    static testMethod void testExportCsvNoParams() {
    
        Test.startTest();  

        Test.setCurrentPageReference(new PageReference('Page.bct_csv_tests'));

        bct_csv_ctlr ctrl = new bct_csv_ctlr();

        Test.stopTest();
    

    }

}