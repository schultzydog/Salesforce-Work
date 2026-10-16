/*
 *  Test class for findUpcomingAppearances
 * */
@isTest
private class FindUpcomingAppearancesTest {
    @testSetup
    private static void makeData(){
        //Create Test Data
        List<Media_Appearance__c> mediaAppearances = new List<Media_Appearance__c>();
        mediaAppearances.addAll(createMediaAppearances('Broadcast',true,false));
        mediaAppearances.addAll(createMediaAppearances('Print/Online',true,true));
        mediaAppearances.addAll(createMediaAppearances('Broadcast',false,false));
        mediaAppearances.addAll(createMediaAppearances('Broadcast',false,true));
        mediaAppearances.addAll(createMediaAppearances('Print/Online',false,false));
        mediaAppearances.addAll(createMediaAppearances('Print/Online',false,true));
        insert mediaAppearances;
        
        
        
    }
    
    @isTest
    private static void testController(){
        //Test findUpcomingAppearances contorller 
        Test.startTest();
            findUpcomingAppearances con = new findUpcomingAppearances();
            system.assertEquals(con.includes.size(), 30);
            //system.assertEquals(con.broadcasts.size(), 10);
            //system.assertEquals(con.printOnlines.size(), 10);
        try{
            //findUpcomingAppearances.sendEmail(new List<String> {'test@test.com'});
        }catch(Exception ex){
            
        }
        Test.stopTest();
    }
    
    
    /**
    * @description: Create Media_Appearance__c record for Testing 
    * @param: mediaType : Broadcast, Print/Online
    * @param: isUpcoming : Is Upcoming appearance
    * @param: includeNextSend: include in the mailer
    * @return: list of Media_Appearance__c
    **/
    private static List<Media_Appearance__c> createMediaAppearances(String mediaType, boolean isUpcoming, boolean includeNextSend){
        List<Media_Appearance__c> mediaApperances = new List<Media_Appearance__c>();
        for(Integer i=0; i<10; i++){
            mediaApperances.add(
                new Media_Appearance__c(
                    Time_text__c = 'This Sunday'
                    , Date__c = Date.Today().adddays((isupcoming ? 1: -1))
                    , Appearance_Summary__c = 'This is Test'
                    , Include_in_next_send__c = includeNextSend
                    , Type__c = mediaType
                    , Sector_Region__c = 'Africa'
                )                
            );
        }
        return mediaApperances;
    }

}