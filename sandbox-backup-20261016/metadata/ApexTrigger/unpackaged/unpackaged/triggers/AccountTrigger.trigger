/**
 * @description       : Trigger on Account 
**/
trigger AccountTrigger on Account (before insert, before update, after update) {
    //Use one EG-custom trigger per object and use this class to launch all business logic
    // which is separated in blogic_Account class
    
    //BEFORE INSERT
    if(Trigger.isBefore && Trigger.isInsert){
        blogic_Account.createNewExternalId(Trigger.New);
    }
    
    //BEFORE UPDATE
    if(Trigger.isBefore && Trigger.isUpdate){
        blogic_Account.createNewExternalId(Trigger.New);     
    }

    //AFTER UPDATE
    if(Trigger.isAfter && Trigger.isUpdate){
        //blogic_Account.triggerContactRollup(Trigger.oldMap , Trigger.newMap);       
    }
    
}