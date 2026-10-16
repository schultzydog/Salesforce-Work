/**
 * @description       : egLogCallController
**/
public with sharing class egLogCallController {
    public egLogCallController() {

    }

    // Get Contact list 

    @AuraEnabled
    public static Map<String,Object> initalize(String recordId){
        //Get User list 
        //Find if this is Contact Id or Account Id 
       Set<Id> accountId = new Set<Id>();
       Set<Id> userIds = new Set<Id>();
       Set<Id> contactIds = new Set<Id>();
       String originatingAccountId;
       String egOppId;
       Event existingEvent;
       Date startDate = Date.today();//DateTime.newInstance(Date.today(), Time.newInstance(10, 00,00,00)) ;
       Opportunity opp;
       OpportunityLineItem oppLineItem;
       Id eventOwnerId = UserInfo.getUserId();
        
        // If this is a Event Id , Event edit scenario
        Schema.SObjectType accountObjectType = Schema.Account.getSObjectType();
        Schema.SObjectType contactObjectType = Schema.Contact.getSObjectType();
        Schema.SObjectType eventObjectType = Schema.Event.getSObjectType();
        Schema.SObjectType oppObjectType = Schema.Opportunity.getSObjectType();
        Schema.SObjectType oppLineObjectType = Schema.OpportunityLineItem.getSObjectType();
        Schema.SObjectType recordType = ((id)recordId).getSObjectType();
        if(recordType == accountObjectType){
            //Do Something
            // If this is account id , default account 
            accountId.add(recordId);
            for(Account con : [SELECT Id,OwnerId FROM Account where Id=:recordId]){
                userIds.add(con.OwnerId);
             }
             originatingAccountId = recordId;
             //contactIds.add(recordId);
        }else if(recordType == contactObjectType){
             // If this is contact id , default account is from Contact
             for(Contact con : [SELECT Id, AccountId,OwnerId FROM Contact where Id=:recordId]){
                accountId.add(con.AccountId);
                userIds.add(con.OwnerId);
                originatingAccountId = con.AccountId;
             }
             contactIds.add(recordId);
        }else if(recordType == oppObjectType){
             // If this is Opporutnity id , default account is from Contact
             opp = [SELECT ID, Name, AccountId, OwnerId FROM Opportunity where Id =:recordId limit 1];
             accountId.add(opp.AccountId);
             userIds.add(opp.OwnerId);
             originatingAccountId = opp.AccountId;
        }else if(recordType == eventObjectType){
            // If this is an existing Event record 
            existingEvent = [SELECT 
                                DurationInMinutes, Subject, Type, Description, OwnerId, StartDateTime, EndDateTime, WhatId, GroupEventType, Opportunity_Product__c
                                , Id, IsChild, WhoCount, WhoId
                            FROM 
                                Event 
                            WHERE Id = :recordId limit 1];
            originatingAccountId = existingEvent.WhatId;      
            startDate = existingEvent.StartDateTime.Date();     
            // Find all existing event relations and set the page
            for(EventRelation relation : [SELECT
                                                EventId,Id,IsInvitee,IsParent,IsWhat,RelationId,Response,Status,AccountId
                                         FROM 
                                            EventRelation
                                         WHERE 
                                            EventId =:existingEvent.Id]){
                
                Schema.SObjectType relationType = (relation.RelationId).getSObjectType();
                if(relationType == contactObjectType){
                    contactIds.add(relation.RelationId);
                }else{
                    userIds.add(relation.RelationId);
                }
                if(originatingAccountId == null && relation.isParent == true) {
                    originatingAccountId = relation.AccountId;
                    contactIds.add(relation.RelationId);
                }

                eventOwnerId = existingEvent.ownerId;
            }

            for(Contact con : [SELECT Id, AccountId,OwnerId FROM Contact where Id IN: contactIds]){
                accountId.add(con.AccountId);
                }

                if(existingEvent.WhatId != null &&  oppObjectType == existingEvent.WhatId.getSObjectType()){
                opp = [SELECT ID, Name FROM Opportunity where Id =:existingEvent.WhatId limit 1];
                originatingAccountId = opp.Id;
                }

                if(existingEvent.Opportunity_Product__c != null){
                oppLineItem = [SELECT ID, Name, OpportunityId, Opportunity.Name FROM OpportunityLineItem where Id =:existingEvent.Opportunity_Product__c limit 1];
                opp = oppLineItem.Opportunity;
                originatingAccountId = opp.Id;

            }

            

            System.debug('originatingAccountId--' + originatingAccountId);
            //SELECT EventId,Id,IsInvitee,IsParent,IsWhat,RelationId,Response,Status FROM EventRelation WHERE EventId = '00U7b000003wJlzEAE'
            //SELECT Description,EndDate,EndDateTime,GroupEventType,Id,IsAllDayEvent,IsChild,IsClientManaged,IsPrivate,WhatCount,WhatId,WhoCount,WhoId FROM Event WHERE Id = '00U7b000003wJlzEAE'

        }

        List<MultiSelectLookupController.SObjectQueryResult> selectedUsers = new List<MultiSelectLookupController.SObjectQueryResult>();
        for(User u: [SELECT Id, Name, Phone, Fax, City FROM User WHERE IsActive = true AND Id  in :userIds and usertype='Standard' order by name]){
            selectedUsers.add (new MultiSelectLookupController.SObjectQueryResult(u, 'Name'));
        }

        List<MultiSelectLookupController.SObjectQueryResult> selectedAccounts = new List<MultiSelectLookupController.SObjectQueryResult>();
        for(Account acc: [SELECT Id, Name, Type, Business_Line__c, BillingCity 
                        FROM Account  where id in :accountId  order by name]){
            selectedAccounts.add (new MultiSelectLookupController.SObjectQueryResult(acc, 'Name'));
        }

        List<MultiSelectLookupController.SObjectQueryResult> selectedContacts = new List<MultiSelectLookupController.SObjectQueryResult>();
        for(Contact con: [SELECT Id, Name, AccountId, Account.Name, Title, Status__c, AccountName__c
                                FROM Contact where id  in  :contactIds  order by name]){
            selectedContacts.add (new MultiSelectLookupController.SObjectQueryResult(con, 'Name'));
        }

        return new Map<String, Object>{
            'selectedUsers' => selectedUsers
            , 'selectedAccounts' => selectedAccounts
            , 'selectedContacts' =>selectedContacts
            , 'originatingAccountId' => originatingAccountId
            , 'defaultToday' => startDate//.format('yyyy-MM-dd')
            , 'existingEvent' => existingEvent
            , 'opportunityLineItem' => oppLineItem
            , 'opportunity' => opp
            , 'eventOwner' => [SELECT Id, Name FROM User Where Id=:eventOwnerId limit 1][0]
        };
    }


    // Get Account list 


    

    @AuraEnabled
    public static String saveEvent(String existingEventId, String subject, String meetingType , Date startDate
                                    ,  integer duraion, String notes, List<String> users
                                    , List<String> contacts, String originatingAccountId
                                    , String opportunityLineItemId
                                    , String eventOwnerId){
       
       Event event = new Event();
       System.Savepoint sp = Database.setSavepoint();
       try{
        Map<Id, EventRelation> exisitngRelations = new Map<Id, EventRelation>();
        if(String.isNotBlank(existingEventId)){
                event = [SELECT 
                                Subject, Type, Description, OwnerId, StartDateTime, EndDateTime, WhatId, GroupEventType, Id, IsChild, WhoCount, WhoId
                        FROM 
                            Event 
                        WHERE Id = :existingEventId limit 1];


                for(EventRelation relation : [SELECT
                                                EventId,Id,IsInvitee,IsParent,IsWhat,RelationId,Response,Status
                                            FROM 
                                                EventRelation
                                            WHERE 
                                                EventId =:event.Id]){

                        
                    exisitngRelations.put(relation.RelationId, relation);      

                }
        }
            
            String egAttendees = '';
            for(User u : [SELECT LastName FROM User where Id in : users]){
                egAttendees += u.LastName + '\n';
            }
            System.debug('--originatingAccountId: ' + originatingAccountId);
            event.Subject = subject;
            event.Type = meetingType;
            event.Description = notes;
            event.OwnerId = eventOwnerId;//UserInfo.getUserId();
            event.StartDateTime = DateTime.newInstance(startDate, Time.newInstance(10,0,0,0));
            event.EndDateTime = event.StartDateTime.addMinutes(duraion);
            event.WhatId = originatingAccountId;
            event.Opportunity_Product__c = opportunityLineItemId;
            event.Assigned_To_Users__c = egAttendees;
            if (String.isBlank(existingEventId)) {
                event.Created_with_Log_a_Call_UI__c = true;
            }
            /*if(contacts.isEmpty() == false){
                event.WhoId = contacts[0];
            }*/
        // event.IsGroupEvent = true;
            upsert event;

            List<EventRelation> ers = new List<EventRelation>();
            for(String conId : contacts){
                
                if(exisitngRelations.containsKey(conId)){
                   // exisitngRelations.get(conId).Status = event.Status;
                    //ers.add(exisitngRelations.get(conId));
                    exisitngRelations.remove(conId);
                }else{
                    ers.add(new EventRelation(
                        EventId = event.Id
                        , IsInvitee	= true
                        , RelationId = conId
                        , isParent = true
                        , Status = 'New'

                    ));
                }
                
                
            }

            for(String userId : users){
                if(exisitngRelations.containsKey(userId)){
                    //exisitngRelations.get(userId).Status = event.Status;
                    //ers.add(exisitngRelations.get(userId));
                    exisitngRelations.remove(userId);
                }else{
                    if(userId != eventOwnerId){
                        ers.add(new EventRelation(
                            EventId = event.Id
                            , IsInvitee	= true
                            , RelationId = userId
                            , Status = 'New'
    
                        ));
                    }
                }

                
            }

            upsert ers;
            delete exisitngRelations.values();
        }catch(Exception ex){
            Database.rollback(sp);
            throw   ex;
        }
        System.debug('--event: ' + event);
       return event.Id;
    }
    
}