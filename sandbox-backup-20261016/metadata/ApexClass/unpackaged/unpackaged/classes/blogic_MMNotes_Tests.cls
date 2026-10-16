@isTest
private class blogic_MMNotes_Tests {
    
    static testmethod void test1() {
        Morning_Meeting_Note__c mmNote = new Morning_Meeting_Note__c();
        mmNote.Proposed_Title__c = 'Test';
        mmNote.egContributors__c = 'schultz@eurasiagroup.net; lieber@eurasiagroup.net';
        mmNote.egLead_Author__c = 'schultz@eurasiagroup.net';
        mmNote.Morning_Meeting_Email__c = 'morningmeeting@eurasiagroup.net';
        mmNote.Distribution_Lists__c = 'schultz@eurasiagroup.net; lieber@eurasiagroup.net';
        mmNote.Topic__c = 'Test';
        
        Test.startTest();   
            insert mmNote;
        Test.stopTest();
    }
    
}