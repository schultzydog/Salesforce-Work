/**
 *  Test class for egLogCallController
 * */
@isTest
private class egLogCallControllerTest {
    
    @isTest
    private static void testController(){
        Account a = new Account(Name='test');
        insert a;
        
        
        Contact c = new Contact(AccountId=a.Id, LastName='test', Email='test2@test.com');
        insert c;
        
        egLogCallController.initalize(a.Id);
        egLogCallController.initalize(c.Id);
        
        
        //String searchText, String searchType, List<String> selectAccountIds, List<String> existingIds
        String eventId = egLogCallController.saveEvent(null, 'Test', 'Meeting', Date.today()
                                 ,  15, 'test', new List<String> {Userinfo.getUserId()}
                                 , new List<String> {c.Id}, a.id, null, UserInfo.getUserId());
        
        
        egLogCallController.initalize(eventId);
        
        eventId = egLogCallController.saveEvent(eventId, 'Test', 'Meeting', Date.today()
                                 ,  15, 'test', new List<String> {Userinfo.getUserId()}
                                 , new List<String> {c.Id}, a.id, null,UserInfo.getUserId());
       
        
        List<MultiSelectLookupController.SObjectQueryResult> results = MultiSelectLookupController.retrieveRecords('Account','Id, Name','Name', 'test','Name != null',null,null);
        for(MultiSelectLookupController.SObjectQueryResult result : results){
            system.assertNotEquals(null, result.label);//expected, actual)
            system.assertNotEquals(null, result.value);
        }
    }

}