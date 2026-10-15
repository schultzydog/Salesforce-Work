public class egEventLogic {
    
    //Create EG Time Entry for each Event attendee
    public static void createEGTimeEntry( Map<Id, Event> eventMap ) {
        
        System.debug( '### createEGTimeEntry' );
        
        try {
            
            //Gather Project ID's
            Set<Id> projectIds = new Set<Id>();
            List<String> eventIds = new List<String>();
            
            for ( Event e : eventMap.values() ) {
                if ( (e.WhatId != null && e.WhatId.getsobjecttype() == Schema.EG_Project__c.getSObjectType()) ) {
                    if ( !e.IsRecurrence2 ) {
                        eventIds.add( e.Id );
                        projectIds.add(e.WhatId);
                    }
                }
            }
            
            if ( eventIds.isEmpty() ) return;
            
            List<Event> events = [SELECT Id, AttendeeIDs__c, WhatId, OwnerId, Owner.Name, Owner.Email, Assigned_To_Users__c, StartDateTime, DurationInMinutes, (SELECT Id, EventId FROM EventRelations) FROM Event WHERE Id in: eventIds AND IsRecurrence2 = FALSE];
            //List<Event> events = [SELECT Id, WhatId, OwnerId, Owner.Name, Owner.Email, Assigned_To_Users__c, StartDateTime, DurationInMinutes, (SELECT Id, EventId FROM EventRelations) FROM Event WHERE Id in: eventIds AND IsRecurrence2 = FALSE];
            Set<Id> updatedEventIds = new Set<Id>();
            
            for ( Event e : events ) {
                
                Integer attendeeSize = 0;
                Set<String> attendeeIDs = new Set<String>();
                if ( e.AttendeeIDs__c != null ) {
                    attendeeIDs = new Set<String>( e.AttendeeIDs__c.split(',') );
                    attendeeSize = attendeeIDs.size();
                }
                
                System.debug('### attendeeSize: ' + attendeeSize);
                System.debug('### e.EventRelations.size(): ' + e.EventRelations.size());
                
                if ( attendeeSize != e.EventRelations.size() + 1 ) {
                    updatedEventIds.add( e.Id );
                }
                
                for ( EventRelation er : e.EventRelations ) {
                    if ( !attendeeIDs.contains( er.Id ) ) {
                        updatedEventIds.add( er.EventId );
                    }
                }
                
            }
            
            if ( updatedEventIds.isEmpty() ) return;
            
            //Query all Event Attendees
            List<EventRelation> relations = [SELECT Id, EventId, Event.WhatId, Event.AttendeeIDs__c, IsInvitee, IsParent, RelationId, Event.StartDateTime, Event.DurationInMinutes FROM EventRelation WHERE EventId in: updatedEventIds];
            
            //Query Projects 
            List<EG_Project__c> projects = [SELECT ID, (SELECT ID FROM EG_Project_Tasks__r) FROM EG_Project__c WHERE Id in: projectIds ];
            
            //Create Map Opportunity -> Maven Project
            Map<Id, EG_Project__c> projectMap = new Map<Id, EG_Project__c>();
            for ( EG_Project__c p : projects ) {
                projectMap.put( p.Id, p );
            }
            
            System.debug( '### projectMap: ' + projectMap );
            
            List<String> contactIds = new List<String>();
            List<String> userIds = new List<String>();
            
            List<String> relationIds = new List<String>();
            List<String> relationsMap = new List<String>();
            Map<Id, EventRelation> relatedRecordIdToRelationMap = new Map<Id, EventRelation>();
            for ( EventRelation er : relations ) {
                relationIds.add( er.RelationId );
                relatedRecordIdToRelationMap.put ( er.RelationId, er );
            }
            
            //Query all related contacts
            List<Contact> contacts = [SELECT Id, Name, Email FROM Contact WHERE Id in: relationIds];
            System.debug( '### contacts : ' + contacts );
            
            List<User> users = [SELECT Id, Name, Email FROM User WHERE Id in: relationIds];
            System.debug( '### users : ' + users );
            
            Map<Id, Set<String>> relationAttendeeMap = new Map<Id, Set<String>>();
            Map<Id, Set<String>> userAttendeeMap = new Map<Id, Set<String>>();
            Map<Id, Set<String>> eventAttendeeMap = new Map<Id, Set<String>>();
            for ( EventRelation er : relations ) {
                if (er.Event.AttendeeIDs__c != null) {
                    String attendees = er.Event.AttendeeIDs__c;
                    Set<String> attendeeSet = new Set<String>(attendees.split(','));
                    relationAttendeeMap.put(er.Id, attendeeSet);
                }
            }
            Set<Id> idSet = new Set<Id>();
            
            //Portal_Setting__mdt settings = [SELECT Allow_Future_Events_in_ML_Integration__c FROM Portal_Setting__mdt WHERE DeveloperName = 'Active_Settings'];
            //Boolean allowFuture = settings.Allow_Future_Events_in_ML_Integration__c;
            
            List<EG_Time_Entry__c> entriesToInsert = new List<EG_Time_Entry__c>();
            
            for ( EventRelation er : relations ) {
                
                if ( (er.RelationId.getsobjecttype() == Schema.Lead.getSObjectType() ) ) {
                    continue; 
                }
                
                //relationIds.add( er.RelationId );
                if ( eventAttendeeMap.containsKey( er.EventId ) ) {
                    eventAttendeeMap.get( er.EventId ).add( er.Id );
                } else {
                    Set<String> attendeeIDs = new Set<String>();
                    attendeeIDs.add( er.Id );
                    eventAttendeeMap.put( er.EventId, attendeeIDs );
                }
                
                if ( relationAttendeeMap.containsKey( er.Id) && relationAttendeeMap.get( er.Id ).contains( er.Id) ){
                    continue;
                }
                
                //Create EG Time Entry
                EG_Time_Entry__c te = new EG_Time_Entry__c();
                
                DateTime dt = er.Event.StartDateTime;
                te.Date__c = date.newinstance(dT.year(), dT.month(), dT.day());
                te.Hours_Worked__c = Decimal.valueOf( er.Event.DurationInMinutes ) / 60;
                
                te.EG_Time_Card__c = findTimeCard(te.Date__c, er.RelationId);
                te.Created_with_Automation__c = true;
                te.Time_Entry_Source__c = 'Automation';
                te.Source_Event_Id__c = String.valueOf( er.EventId );
                te.EG_Project__c = er.Event.WhatId;
                
                if ( projectMap.containsKey( er.Event.WhatId ) ) {
                    if ( projectMap.get( er.Event.WhatId ).EG_Project_Tasks__r.size() == 1 ) {
                        te.EG_Project_Task__c = projectMap.get( er.Event.WhatId ).EG_Project_Tasks__r[0].Id;
                    }
                }
                
                String externalId = te.EG_Time_Card__c+':'+te.EG_Project__c+':'+te.EG_Project_Task__c+':'+te.Date__c;
                te.ExternalID__c = externalId;
                
                if (te.EG_Time_Card__c != null) {
                    entriesToInsert.add(te);
                }
                
            }
            
            for ( Event e : events ) {
                
                if (e.AttendeeIDs__c != null && e.AttendeeIDs__c.contains(e.OwnerId)){
                    continue;
                }
                
                //Create EG Time Entry
                EG_Time_Entry__c te = new EG_Time_Entry__c();
                
                DateTime dt = e.StartDateTime;
                te.Date__c = date.newinstance(dT.year(), dT.month(), dT.day());
                te.Hours_Worked__c = Decimal.valueOf( e.DurationInMinutes ) / 60;
                
                te.EG_Time_Card__c = findTimeCard(te.Date__c, e.OwnerId);
                te.Created_with_Automation__c = true;
                te.Time_Entry_Source__c = 'Automation';
                te.Source_Event_Id__c = String.valueOf( e.Id );
                te.EG_Project__c = e.WhatId;
                
                if ( projectMap.containsKey( e.WhatId ) ) {
                    if ( projectMap.get( e.WhatId ).EG_Project_Tasks__r.size() == 1 ) {
                        te.EG_Project_Task__c = projectMap.get( e.WhatId ).EG_Project_Tasks__r[0].Id;
                    }
                }
                
                String externalId = te.EG_Time_Card__c+':'+te.EG_Project__c+':'+te.EG_Project_Task__c+':'+te.Date__c;
                te.ExternalID__c = externalId;
                
                if (te.EG_Time_Card__c != null) {
                    entriesToInsert.add(te);
                }
                
            }
            
            insert entriesToInsert;
            
            List<Event> eventsToUpdate = new List<Event>();
            for ( Event e : events ) {
                
                System.debug('### event: '+e);
                List<String> idList = new List<String>();
                for ( EventRelation er : e.EventRelations ) {
                    System.debug('### adding id: '+er.Id);
                    idList.add( er.Id );
                }
                idList.add(e.OwnerId);
                e.AttendeeIDs__c = String.join(idList,',');
                eventsToUpdate.add( e );
            }
            
            update eventsToUpdate;
            
        } catch ( Exception e ) {
            System.debug( '### ERROR: ' + e.getMessage() + ' : ' + e.getStackTraceString() );
            throw e;
        }
        
    }
    
    public static Id findTimeCard(Date d, String userOrContactId) {
        
        Date dateMin;
        Date dateMax;
        List<Id> userIds = new List<Id>();
        
        Id userId = findUserId(userOrContactId);
        
        List<EG_Time_Card__c> timeCards = [SELECT ID, Start_Date__c, End_Date__c, OwnerId FROM EG_Time_Card__c WHERE Start_Date__c <=: d AND End_Date__c >=: d AND OwnerId =: userId ];
        
        if ( timeCards.size() > 0 ) {
            return timeCards[0].Id;
        } else {
            return null;
        }
    }
    
    public static Id findUserId(Id userOrContactId){
        
        if ( userOrContactId.getsobjecttype() == Schema.User.getSObjectType() ) {
            return userOrContactId;
        } else {
            if ( userOrContactId.getsobjecttype() == Schema.Contact.getSObjectType() ){
                try {
                Contact c = [SELECT ID, Email FROM Contact WHERE Id =: userOrContactId];
                User u = [SELECT ID FROM User WHERE Email =: c.Email];
                return u.Id;
                } catch (Exception e) {
                    return null;
                }
            }
        }
        return null;
        
    }
    
}
