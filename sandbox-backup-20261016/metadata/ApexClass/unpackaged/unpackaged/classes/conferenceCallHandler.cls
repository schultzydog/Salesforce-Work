public class conferenceCallHandler {
    
    public static void createEvents(Map<Id, Conference_Call__c> oldMap, List<Conference_Call__c> newccs) {

        List<Id> ids = new List<Id>(); 
        List<Event> events = new List<Event>();
        List<EG_Event_Registrant__c> leadAttendees = new List<EG_Event_Registrant__c>();
        List<EG_Event_Registrant__c> contactAttendees = new List<EG_Event_Registrant__c>();
        List<EventRelation> relations = new List<EventRelation>();
        
        for (Conference_Call__c cc : newccs) {
            if (oldMap.get(cc.Id).Create_Activity_History__c == FALSE && cc.Create_Activity_History__c) ids.add(cc.id);
            else return;
            
        }
        
        List<Conference_Call__c> ccs = [SELECT Id, Name, Date__c, Description__c, Event_Start_Time__c, Event_End_Time__c, 
                                        Speaker_Departments__c , Speaker_Names__c, Type__c, Count_of_Contact_Attendees__c,
                                        Count_of_Lead_Attendees__c,                                        
                                        (SELECT Lead__c, Contact__c, Contact__r.AccountId FROM EG_Event_Registrant__r  WHERE Attended__c = TRUE 
                                           AND (NOT Email__c LIKE '%eurasiagroup.net%') AND (Contact__c != NULL or Lead__c != NULL))
                                        //(SELECT Contact__c FROM Conference_Call_Contacts__r WHERE Attended__c = TRUE Order By Contact__r.AccountId ASC NULLS FIRST),
                                        //(SELECT Lead__c FROM Conference_Call_Leads__r WHERE Attended__c = TRUE)
                                        FROM Conference_Call__c WHERE Id IN :ids];
                              
                                        
        List<Event> deleteEvents = [SELECT Id FROM Event WHERE WhatId IN :ids OR Conference_Call__c IN : ids];
        if (deleteEvents.size()>0) delete deleteEvents;
        
        for (EG_Event_Registrant__c er : ccs[0].EG_Event_Registrant__r) {
            if (er.Contact__c != NULL) contactAttendees.add(er);
            else if (er.Lead__c != NULL) leadAttendees.add(er);         
        }  

        Decimal d = contactAttendees.size()/50.0;
        system.debug('### d = ' +d ); 
        
        if (contactAttendees.size() > 0) {
            //for (Integer i = 0 ; i < ccs[0].Number_of_Contact_Attendees__c/50 ; i++) {
            for (Decimal i = 0 ; i < contactAttendees.size()/50.0 ; i++) {
                system.debug('### i = ' + i);  
                Event eventTemp = new Event(Subject = ccs[0].Name,StartDateTime = ccs[0].Event_Start_Time__c, Activity_Type__c = ccs[0].Type__c, Type = ccs[0].Type__c,
                                            Contact_Lead__c = 'Contact', EndDateTime = ccs[0].Event_End_Time__c, WhatId = ccs[0].Id, Conference_Call__c = ccs[0].Id,
                                            Assigned_To_Users__c = ccs[0].Speaker_Names__c, Description = ccs[0].Description__c ); 
                events.add(eventTemp); 
            }
            system.debug('### contact events = ' + events);
            insert events;
    
            List<Event> cccEvents = [SELECT Id FROM Event WHERE WhatId IN :ids AND Contact_Lead__c = 'Contact']; 
            //creating contact eventrelations
            //for (Integer i = 0 ; i < ccs[0].Number_of_Contact_Attendees__c/50 ; i++) {
            for (Decimal i = 0 ; i < contactAttendees.size()/50.0 ; i++) {       
                for(Decimal j=(i*50.0);(j<(i*50.0)+50.0) && j<contactAttendees.size()/1.0 ; j++){ 
                    Integer jI = j.intValue();
                    Integer iI = i.intValue();
                    system.debug('### j = ' + j); 
                    system.debug('### jI = ' + jI); 
                    system.debug('### i = ' + i);              
                    system.debug('### iI = ' + iI); 
                       
                    //EventRelation conER = new EventRelation(EventId = cccEvents[i].Id, RelationId = ccs[0].Conference_Call_Contacts__r[j].Contact__c, isParent = TRUE);
                    EventRelation conER = new EventRelation(EventId = cccEvents[iI].Id, RelationId = contactAttendees[jI].Contact__c, isParent = TRUE);
                     
                    relations.add(conER);        
                }  
            }
        }
        //creating lead event relations
        List<Event> leadEvents = new List<Event>();
        
        if (leadAttendees.size() > 0) {
            //for (Conference_Call_Lead__c ccl : ccs[0].Conference_Call_Leads__r) {
            for (EG_Event_Registrant__c ccl : leadAttendees) {
                Event eventTemp = new Event(Subject = ccs[0].Name,StartDateTime = ccs[0].Event_Start_Time__c, Activity_Type__c = ccs[0].Type__c, Type = ccs[0].Type__c,
                                            Contact_Lead__c = 'Lead', EndDateTime = ccs[0].Event_End_Time__c, WhatId = ccs[0].Id, Conference_Call__c = ccs[0].Id,
                                            Assigned_To_Users__c = ccs[0].Speaker_Names__c, Description = ccs[0].Description__c); 
                                           
                leadEvents.add(eventTemp);                 
            } 
            
            insert leadEvents;
            
            List<Event> cclEvents = [SELECT Id, What.Name, Contact_Lead__c  FROM Event WHERE WhatId IN :ids AND Contact_Lead__c = 'Lead']; 
            List<EventRelation> deletes = [SELECT Id FROM EventRelation WHERE EventId IN : cclEvents];
            delete deletes;
            //system.debug('### cclEvents  ' + cclEvents.size() );
            //for (Integer i = 0 ; i < ccs[0].Number_of_Lead_Attendees__c ; i++) {
            for (Integer i = 0 ; i < leadAttendees.size() ; i++) {
                system.debug('### cclEvents  ' + cclEvents[i] );
                EventRelation leadER = new EventRelation(EventId = cclEvents[i].Id, RelationId = leadAttendees[i].Lead__c, isParent = TRUE);
                //system.debug('### leadER  = ' + leadER );  
                relations.add(leadER);                    
            }                         
        }
         
        system.debug('### relation size = ' + relations.size());
        insert relations;      
    }  
  
    //This is trigger handler method is not bulkified as all of this work is done on individual conf call records in sf
    public static void populateEGAttendeesDept(List<Conference_Call__c> newccs) {
        
        String speakerListDeptString;
        String speakerListString;
        system.debug('### newccs = ' + newccs);              
                              
        List<Conference_Call_Speaker__c> speakers = [SELECT Speaker__r.Name, Speaker_User__r.Name, Speaker_User__r.Department__c
                                            FROM Conference_Call_Speaker__c WHERE Conference_Call__c  =: newccs[0].Id];
       
        List<String> speakerList = new List<String>();
        Set<String> speakerDeptSet = new Set<String>();
        List<String> speakerDeptList = new List<String>();
        if (speakers.size() > 0 ) {
            for(Conference_Call_Speaker__c speaker: speakers ) {
                if (speaker.Speaker_User__c != null && speaker.Speaker_User__r.Department__c != null) {
                    speakerDeptSet.add(String.valueOf(speaker.Speaker_User__r.Department__c).Trim());
                    system.debug('### speaker dept speaker.Speaker_User__r.Department__c= ' +  speaker.Speaker_User__r.Department__c);
                }
                speakerList.add(String.valueOf(speaker.Speaker__r.Name));
                
            }
            speakerDeptList.addAll(speakerDeptSet );
            speakerListDeptString = String.join(speakerDeptList, ';');
            speakerListDeptString.removeEnd(';');
            speakerListString = String.join(speakerList, ';');
            speakerListString.removeEnd(';');

            system.debug('### speaker dept speakerListDeptString = ' + speakerListDeptString);
            if (speakerListDeptString != null && speakerListDeptString.length() > 254) newccs[0].Speaker_Departments__c = speakerListDeptString.substring(0, 255);
                else if (speakerListDeptString != null) newccs[0].Speaker_Departments__c = speakerListDeptString;
            
            if (speakerListString != null && speakerListString.length() > 254) newccs[0].Speaker_Names__c = speakerListString.substring(0, 255);
                else if (speakerListString != null) newccs[0].Speaker_Names__c = speakerListString;   
        }
    }
}