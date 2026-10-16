/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-30-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class MorningMeetingNotesCtrl {
   @AuraEnabled
   public static LWCResponse saveNote(Morning_Meeting_Note__c note){
    LWCResponse response = new LWCResponse();
    response.isSuccess = false;
    try {
        List<User> exisitngUsers = [SELECT ID 
                                    FROM USER 
                                    WHERE 
                                        Email=:note.Submitted_by_Email__c
                                        AND IsActive = true 
                                        AND UserType = 'Standard'
                                    Limit 1];
        if(exisitngUsers.isEmpty()){
            response.errorMessage = 'User not found, this note will not be submitted';
        }else{
            insert note;
            response.isSuccess = true;
        }
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
    return response;
   }


   public class LWCResponse{
        @AuraEnabled
        public boolean isSuccess;
        @AuraEnabled
        public String errorMessage;
   }
}