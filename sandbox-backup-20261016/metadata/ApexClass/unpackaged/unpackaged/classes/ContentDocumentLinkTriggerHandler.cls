/***
 *  Handler class for Trigger on Content Document Link Object
 *   Event
 *     - After Insert - Link Document from Opportunity to Account * 
 ***/
public class ContentDocumentLinkTriggerHandler { 
    private Map<Id, ContentDocumentLink> newMap; //Trigger new Map
    private Map<Id, ContentDocumentLink> oldMap; //Trigger old Map
    private List<ContentDocumentLink> newList; //Trigger old Map

    public ContentDocumentLinkTriggerHandler() {
        this.newMap = (Map<Id, ContentDocumentLink>) Trigger.newMap;
        this.oldMap = (Map<Id, ContentDocumentLink>) Trigger.oldMap;
        this.newList = (List<ContentDocumentLink>)Trigger.New;
    }
    
    public void run(){
        if(Trigger.isAfter && Trigger.isInsert){
            this.afterInsert();
        }
    }
    
     //After Insert Trigger handler 
    private void afterInsert(){
        //Find if content is linked with Opportunity object
        Map<Id,Set<Id>> mapLinkedIdToContentDocId = new Map<Id,Set<Id>>();
        for(ContentDocumentLink cdl : newMap.values()){
            //If this is linked with Opportunity object 
            if(String.isNotBlank(cdl.LinkedEntityId) 
               && cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Opportunity'){
                   if(mapLinkedIdToContentDocId.containsKey(cdl.LinkedEntityId)){
                       mapLinkedIdToContentDocId.get(cdl.LinkedEntityId).add(cdl.Id);
                   }else{
                       mapLinkedIdToContentDocId.put(cdl.LinkedEntityId, new Set<Id>{cdl.Id}); 
                   }
               }
        }
        
        
        if(! mapLinkedIdToContentDocId.isEmpty()){
            List<ContentDocumentLink> accountCDLinks = new List<ContentDocumentLink>();
            //Find Accounts for Opportunity record and clone related content document link
            for(Opportunity opp: [SELECT ID, AccountId FROM Opportunity WHERE Id in:mapLinkedIdToContentDocId.keySet()]){
                for(Id cdLinkId : mapLinkedIdToContentDocId.get(opp.Id)){   
                    ContentDocumentLink cdLink = newMap.get(cdLinkId);
                    accountCDLinks.add(
                        new ContentDocumentLink(
                            ContentDocumentId = cdLink.ContentDocumentId
                            , LinkedEntityId = opp.AccountId
                            , ShareType = cdLink.ShareType
                        )                     
                    );
                    /*
                    accountCDLinks.add(
                        //this creates a share for Ana A
                        new ContentDocumentLink(
                            ContentDocumentId = cdLink.ContentDocumentId
                            , LinkedEntityId = '0054V00000GC00F'
                            , ShareType = 'C'
                        )                     
                    ); 
                    */                   
                }
            }
            system.debug('--accountCDLinks ' + accountCDLinks);
            //Create accountCDLinks record 
            if(! accountCDLinks.isEmpty()){
                insert accountCDLinks;
            }
        }
        
        
    }

}