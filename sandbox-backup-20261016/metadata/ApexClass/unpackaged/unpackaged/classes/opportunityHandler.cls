public without sharing class opportunityHandler {
    
    private static Boolean EG_PROJECTS_SYNC_HAS_RUN_ONCE = false;

    public static void syncProjectsAndTasksWithOpportunitiesAndProducts(Map<Id, Opportunity> mapOpps) {
        //This is always the entry point for this logic, this method will determine what context to use
        // Ultimately, the logic will be run asyncronously regardless of original context.
        if(!EG_PROJECTS_SYNC_HAS_RUN_ONCE){        
            EG_PROJECTS_SYNC_HAS_RUN_ONCE = true; //prevent recursion on Opportunity two-way link update
            
            //Decide if in "async" context already...
            if(System.isBatch() || System.isFuture() || System.isQueueable()){
                //already in an "async" context, continue without calling @future, just call the logic...
                syncProjectsAndTasksWithOpportunitiesAndProducts_Logic(mapOpps.keySet());
            } else {
                //not in an "async" context, use @Future wrapper...
                syncProjectsAndTasksWithOpportunitiesAndProducts_AtFuture(mapOpps.keySet());
            }
        }
    }
    
    @future
    public static void syncProjectsAndTasksWithOpportunitiesAndProducts_AtFuture(Set<Id> oppIds) {
        //This is just an "@future" wrapper to exectue logic the logic...
        syncProjectsAndTasksWithOpportunitiesAndProducts_Logic(oppIds);
    }

    public static void syncProjectsAndTasksWithOpportunitiesAndProducts_Logic(Set<Id> oppIds) {
        //Centralized logic for syncing EG Projects and Project Tasks with Opportunities and Opportunity Products...

        //Get Custom Metadata Type settings from Timesheets_Setting__mdt "active" record...
        List<Timesheets_Setting__mdt> settings = [SELECT 
                                                  Sync_Projects_and_Project_Tasks_from_Opp__c,
                                                  Sync_Projects_and_Project_Tasks_OwnerId__c,
                                                  Opportunity_Probability_for_Sync__c
                                                  FROM Timesheets_Setting__mdt
                                                  WHERE DeveloperName = 'active'
                                                  LIMIT 1];
        Boolean OPPS_PROJECTS_SYNC_ACTIVE = settings[0].Sync_Projects_and_Project_Tasks_from_Opp__c;
        Decimal PROBABILITY_THRESHOLD_FOR_SYNC = (settings[0].Opportunity_Probability_for_Sync__c!=null) ? (settings[0].Opportunity_Probability_for_Sync__c / 100.0) : 0.10;
        String EG_PROJECTS_OWNERID = settings[0].Sync_Projects_and_Project_Tasks_OwnerId__c;
        
        if(OPPS_PROJECTS_SYNC_ACTIVE){ //master switch for all of this logic syncProjectsAndTasksWithOpportunitiesAndProducts_Logic
            //List for all of the necessary DML statements...
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();
            List<EG_Project__c> projectsToUpsert = new List<EG_Project__c>();
            List<EG_Project_Task__c> projectTasksToUpsert = new List<EG_Project_Task__c>();
            List<Error_Log__c> errorLogsToInsert = new List<Error_Log__c>();
    
            //Build maps of all relevant data...
            Map<Id, Opportunity> mapOppsById = new Map<Id, Opportunity>([SELECT Id, Name, Probability, 
                                                                         Linked_EG_Project__c 
                                                                         FROM Opportunity 
                                                                         WHERE Id IN :oppIds 
                                                                         AND AccountId != '00130000016FGqU']);
                                                                       
            
            Map<Id, OpportunityLineItem > mapOlisbyId = new Map<Id, OpportunityLineItem >([SELECT Id, OpportunityId, Product2.Name, Business_Line__c,
                                                                                           Linked_EG_Project_Task__c 
                                                                                           FROM OpportunityLineItem  
                                                                                           WHERE OpportunityId IN :oppIds]);
            
            Map<Id, EG_Project__c> mapEgProjectsById = new Map<Id, EG_Project__c>([SELECT Id, Name, Status__c, 
                                                                                   Linked_Opportunity__c,
                                                                                   (SELECT Id FROM EG_Time_Entries__r ORDER BY Name LIMIT 1)
                                                                                   FROM EG_Project__c
                                                                                   WHERE Linked_Opportunity__c IN :mapOppsById.keySet()
                                                                                   AND Is_Internal__c = FALSE
                                                                                   ORDER BY CreatedDate DESC]);
                
            Map<Id, EG_Project__c> mapEgProjectsByOppId = new Map<Id, EG_Project__c>();
            for(EG_Project__c project : mapEgProjectsById.values()){
                if(project.Linked_Opportunity__c!=null){
                    mapEgProjectsByOppId.put(project.Linked_Opportunity__c, project);
                }
            }
            
            Map<Id, EG_Project_Task__c> mapEgProjectTasksById = new Map<Id, EG_Project_Task__c>([SELECT Id, Name, Status__c,
                                                                                                 Linked_Opportunity_Product__c,
                                                                                                 (SELECT Id FROM EG_Time_Entries__r ORDER BY Name LIMIT 1)
                                                                                                 FROM EG_Project_Task__c
                                                                                                 WHERE (Linked_Opportunity_Product__r.OpportunityId IN :mapOppsById.keySet()
                                                                                                 OR EG_Project__c IN :mapEgProjectsById.keySet()) 
                                                                                                 AND EG_Project__r.Is_Internal__c = FALSE]);
            
            Map<Id, EG_Project_Task__c> mapEgProjectTasksByOliId = new Map<Id, EG_Project_Task__c>();
            for(EG_Project_Task__c projectTask : mapEgProjectTasksById.values()){
                if(projectTask.Linked_Opportunity_Product__c!=null){
                    mapEgProjectTasksByOliId.put(projectTask.Linked_Opportunity_Product__c, projectTask);
                }
            }
            
            //Sync Opportunities to EG Projects...
            List<Opportunity> oppsToSync = new List<Opportunity>();
            List<Opportunity> oppsToDeactivate = new List<Opportunity>();
            
            for(Opportunity opp : mapOppsById.values()){
                if(opp.Probability >= PROBABILITY_THRESHOLD_FOR_SYNC){
                    //Probability greater or equal to threshold...
                    oppsToSync.add(opp);
                } else if(opp.Linked_EG_Project__c!=null){
                    //Probability below threshold and was previously synced...
                    oppsToDeactivate.add(opp);
                }
            }
            
            for(Opportunity opp : oppsToSync){
                EG_Project__c project = mapEgProjectsByOppId.get(opp.Id);
                String Name = opp.Name;
                if (Name.length() > 79) Name = Name.substring(0,79);
                
                if(project==null){
                    //Create new EG Project record... 
                    project = new EG_Project__c(
                        OwnerId = EG_PROJECTS_OWNERID,
                        Linked_Opportunity__c = opp.Id,
                        Name = Name,
                        Status__c = 'Active'
                    );
                    projectsToUpsert.add(project);
                } else {
                    //Check for updates of relevant fields...
                    //if(opp.Name!=project.Name || project.Status__c!='Active'){ //commented out, always add to upsert list or some bugs might occur - bry 5/22/23
                        project.Name = Name; //Always sync Name
                        project.Status__c = 'Active'; //Always confirm Status                        
                        projectsToUpsert.add(project);                
                    //}
                }            
            }
    
            for(Opportunity opp : oppsToDeactivate){
                EG_Project__c project = mapEgProjectsByOppId.get(opp.Id);
    
                if(project!=null){ 
                    if(project.EG_Time_Entries__r.isEmpty()){
                        //No EG Time Entries have been logged to this Project...
                        // Set Project Status__c to Inactive... (could also physically delete)
                        if(project.Status__c!='Inactive'){
                            project.Status__c = 'Inactive';
                        }
                    } else {
                        //At least one EG Time Entries have been logged to this Project...
                        // Keep Project Status__c as whatever it currently is (Active/Inactive)
                        // At first it will remain Active, but can be manually changed to Inactive by Administrator...
                        // when they want it to no longer be available for end users.
                    }
                    projectsToUpsert.add(project);                
                }                        
            }
            
            system.debug('projectsToUpsert ' + projectsToUpsert);
            
            //Upsert EG Projects...
            if(!projectsToUpsert.isEmpty()){
                upsert projectsToUpsert;
            }
    
            //Rebuild map of EG Projects with new Ids...
            Map<Id, EG_Project__c> mapEgProjectsByOppIdAfterUpsert = new Map<Id, EG_Project__c>();
            for(EG_Project__c project : projectsToUpsert){
                if(project.Linked_Opportunity__c!=null){
                    mapEgProjectsByOppIdAfterUpsert.put(project.Linked_Opportunity__c, project);
                }
            }
            
            system.debug('mapEgProjectsByOppIdAfterUpsert ' + mapEgProjectsByOppIdAfterUpsert);
            
            //Sync Opportunity Products to EG Project Tasks...
            List<OpportunityLineItem> olisToSync = new List<OpportunityLineItem>();
            List<OpportunityLineItem> olisToDeactivate = new List<OpportunityLineItem>();
            
            system.debug('mapOlisbyId ' + mapOlisbyId);
            for(OpportunityLineItem oli : mapOlisbyId.values()){
                Opportunity opp = mapOppsById.get(oli.OpportunityId);
                system.debug('opp ' + opp);
                if(opp.Probability >= PROBABILITY_THRESHOLD_FOR_SYNC){
                    //Probability greater or equal to threshold...
                    olisToSync.add(oli);
                } else if(opp.Linked_EG_Project__c!=null){
                    //Probability below threshold and was previously synced...
                    olisToDeactivate.add(oli);
                }
            }
            system.debug('olisToSync ' + olisToSync);
            system.debug('olisToDeactivate ' + olisToDeactivate);
    
            for(OpportunityLineItem oli : olisToSync){
                EG_Project_Task__c projectTask = mapEgProjectTasksByOliId.get(oli.Id);
                EG_Project__c project = mapEgProjectsByOppIdAfterUpsert.get(oli.OpportunityId);
    
                system.debug('projectTask ' + projectTask);
                system.debug('project ' + project);
                
                if(projectTask==null){
                    if(project!=null){ //Every once in a while, this was throwing exceptions dereferencing project.Id, not sure why - Bryan 9/3/22
                        //Create new EG Project Task record...
                        projectTask = new EG_Project_Task__c(
                            OwnerId = EG_PROJECTS_OWNERID,
                            EG_Project__c = project.Id,
                            Linked_Opportunity_Product__c = oli.Id,
                            Name = oli.Product2.Name, 
                            Status__c = 'Active',
                            Business_Line__c = oli.Business_Line__c
                        );
                        projectTasksToUpsert.add(projectTask);
                    } 
                } else {
                    //Check for updates of relevant fields...
                    //if(oli.Product2.Name!=projectTask.Name || projectTask.Status__c!='Active'){ //commented out, always add to upsert list or some tasks will get missed - bry 5/22/23
                        projectTask.Name = oli.Product2.Name; //always sync Name
                        projectTask.Status__c = 'Active'; //always confirm Status
                        projectTasksToUpsert.add(projectTask);                
                    //}
                }            
            }
    
            for(OpportunityLineItem oli : olisToDeactivate){
                EG_Project_Task__c projectTask = mapEgProjectTasksByOliId.get(oli.Id);
                EG_Project__c project = mapEgProjectsByOppIdAfterUpsert.get(oli.OpportunityId);
    
                if(projectTask!=null){
                    if(projectTask.EG_Time_Entries__r.isEmpty()){
                        //No EG Time Entries have been logged to this Project Task...                
                        //Set Project Task Status__c to Inactive... (could also physically delete)
                        if(projectTask.Status__c!='Inactive'){
                            projectTask.Status__c = 'Inactive';
                        }
                    } else {
                        //At least one EG Time Entries have been logged to this Project Task...
                        // Keep Project Task Status__c as whatever it currently is (Active/Inactive)
                        // At first it will remain Active, but can be manually changed to Inactive by Administrator
                        // when they want it to no longer be available for end users.
                    }                    
                    projectTasksToUpsert.add(projectTask);                
                }                        
            }
    
            system.debug('projectTasksToUpsert ' + projectTasksToUpsert);
            
            //Upsert EG Project Tasks...
            if(!projectTasksToUpsert.isEmpty()){
                upsert projectTasksToUpsert;
            }
            
            //Update two-way links on Opportunities...
            for(EG_Project__c project : projectsToUpsert){
                oppsToUpdate.add(new Opportunity(Id=project.Linked_Opportunity__c, Linked_EG_Project__c=project.Id));
            }
            if(!oppsToUpdate.isEmpty()){
                List<Database.SaveResult> saveResults = Database.update(oppsToUpdate, false);
            }
            
            //Update two-way links on Opportunity Products...
            for(EG_Project_Task__c projectTask : projectTasksToUpsert){
                olisToUpdate.add(new OpportunityLineItem(Id=projectTask.Linked_Opportunity_Product__c, Linked_EG_Project_Task__c=projectTask.Id));
            }
            if(!olisToUpdate.isEmpty()){
                List<Database.SaveResult> saveResults = Database.update(olisToUpdate, false);
            }
            
        }
    }

}