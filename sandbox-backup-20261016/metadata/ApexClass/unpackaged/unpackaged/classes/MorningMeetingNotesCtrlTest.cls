/** 
 * @description       :  Test class for MorningMeetingNotesCtrl
**/

@isTest
private class MorningMeetingNotesCtrlTest {
    @IsTest
    static void testSaveNote() {

        Morning_Meeting_Note__c note = EGTestDataGenerator.getMMNotes(UserInfo.getUserEmail())[0];
        MorningMeetingNotesCtrl.LWCResponse res =  MorningMeetingNotesCtrl.saveNote(note);
        Assert.areEqual(res.isSuccess , true);

         note = EGTestDataGenerator.getMMNotes(UserInfo.getUserEmail() + '.invalid')[0];
         res =  MorningMeetingNotesCtrl.saveNote(note);
        Assert.areEqual(res.isSuccess , false);

    }
}