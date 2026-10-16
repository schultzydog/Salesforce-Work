public class ActivityHistoryController {
    
    @AuraEnabled
    public static List<ActivityWrapper> getActivityHistoryApex(String recordId) {
        
        List<ActivityWrapper> wrappers = new List<ActivityWrapper>();
        
        //List<TaskWhoRelation> taskWhoRelations = [SELECT Id, RelationId, Relation.Name, TaskId, Task.Subject, Task.ActivityDate, Task.OwnerId, Task.Owner.Name FROM TaskWhoRelation WHERE RelationId =: recordId];
        List<TaskRelation> taskRelations = [SELECT Id, AccountId, Account.Name, RelationId, Relation.Name, TaskId, Task.Subject, Task.ActivityDate, Task.OwnerId, Task.Owner.Name, Task.WhoId, Task.Who.Name, Task.WhatId, Task.What.Name FROM TaskRelation WHERE ( RelationId =: recordId OR AccountId =: recordId )];
        //List<Task> tasks = [SELECT Id, Subject, ActivityDate, WhoId, Who.Name, WhatId, What.Name, OwnerId, Owner.Name FROM Task WHERE (WhatId =: recordId OR WhoId =: recordId)];
        
        //List<EventWhoRelation> eventWhoRelations = [SELECT Id, RelationId, Relation.Name, EventId, Event.Subject, Event.ActivityDate, Event.OwnerId, Event.Owner.Name FROM EventWhoRelation WHERE RelationId =: recordId];
        List<EventRelation> eventRelations = [SELECT Id, AccountId, Account.Name, RelationId, Relation.Name, EventId, Event.Subject, Event.ActivityDate, Event.OwnerId, Event.Owner.Name, Event.WhoId, Event.Who.Name, Event.WhatId, Event.What.Name FROM EventRelation WHERE ( RelationId =: recordId OR AccountId =: recordId )];
        //List<Event> events = [SELECT Id, Subject, ActivityDate, WhoId, Who.Name, WhatId, What.Name, OwnerId, Owner.Name FROM Event WHERE (WhatId =: recordId OR WhoId =: recordId)];
        
        Set<Id> taskIds = new Set<Id>();
        for (TaskRelation t : taskRelations) {
            ActivityWrapper wrap = new ActivityWrapper();
            wrap.id = t.TaskId;
            wrap.subject = t.Task.subject;
            wrap.activityDate = t.Task.ActivityDate;
            wrap.who = new Thing(t.Task.WhoId, t.Task.Who.Name);
            wrap.whoid = t.RelationId;
            wrap.whoname = t.Relation.Name;
            wrap.what = new Thing(t.Task.WhatId, t.Task.What.Name);
            wrap.whatid = t.AccountId;
            wrap.whatname = t.Account.Name;
            wrap.owner = new Thing(t.Task.OwnerId, t.Task.Owner.Name);
            wrap.ownerid = t.Task.OwnerId;
            wrap.ownername = t.Task.Owner.Name;
            
            if (!taskIds.contains(t.TaskId)){
            	wrappers.add(wrap);
            }
            taskIds.add(t.TaskId);
        }        
        
        /*
        for (Task t : tasks) {
            ActivityWrapper wrap = new ActivityWrapper();
            wrap.id = t.Id;
            wrap.subject = t.subject;
            wrap.activityDate = t.ActivityDate;
            wrap.who = new Thing(t.WhoId, t.Who.Name);
            wrap.whoid = t.WhoId;
            wrap.whoname = t.Who.Name;
            wrap.what = new Thing(t.WhatId, t.What.Name);
            wrap.whatid = t.WhatId;
            wrap.whatname = t.What.Name;
            wrap.owner = new Thing(t.OwnerId, t.Owner.Name);
            wrap.ownerid = t.OwnerId;
            wrap.ownername = t.Owner.Name;
            wrappers.add(wrap);
        }
		*/
        
        Set<Id> eventIds = new Set<Id>();
        for (EventRelation e : eventRelations) {
            ActivityWrapper wrap = new ActivityWrapper();
            wrap.id = e.EventId;
            wrap.subject = e.Event.subject;
            wrap.activityDate = e.Event.ActivityDate;
            wrap.who = new Thing(e.Event.WhoId, e.Event.Who.Name);
            wrap.whoid = e.RelationId;
            wrap.whoname = e.Relation.Name;
            wrap.what = new Thing(e.Event.WhatId, e.Event.What.Name);
            wrap.whatid = e.AccountId;
            wrap.whatname = e.Account.Name;
            wrap.owner = new Thing(e.Event.OwnerId, e.Event.Owner.Name);
            wrap.ownerid = e.Event.OwnerId;
            wrap.ownername = e.Event.Owner.Name;
            
            if (!eventIds.contains(e.EventId)){
            	wrappers.add(wrap);
            }
            eventIds.add(e.EventId);
        } 
        
        /*
        for (Event e : events) {
            ActivityWrapper wrap = new ActivityWrapper();
            wrap.id = e.Id;
            wrap.subject = e.subject;
            wrap.activityDate = e.ActivityDate;
            wrap.who = new Thing(e.WhoId, e.Who.Name);
            wrap.whoid = e.WhoId;
            wrap.whoname = e.Who.Name;
            wrap.what = new Thing(e.WhatId, e.What.Name);
            wrap.whatid = e.WhatId;
            wrap.whatname = e.What.Name;
            wrap.owner = new Thing(e.OwnerId, e.Owner.Name);
            wrap.ownerid = e.OwnerId;
            wrap.ownername = e.Owner.Name;
            wrappers.add(wrap);
        }
		*/
        
        wrappers.sort();
        
        return wrappers;
    }
    
    public class ActivityWrapper implements Comparable {
        
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public String subject {get;set;}
        @AuraEnabled
        public Thing who {get;set;}
        @AuraEnabled
        public String whoid {get;set;}
        @AuraEnabled
        public String whoname {get;set;}
        @AuraEnabled
        public Thing what {get;set;}
        @AuraEnabled
        public String whatid {get;set;}
        @AuraEnabled
        public String whatname {get;set;}
        @AuraEnabled
        public Date activityDate {get;set;}
        @AuraEnabled
        public Thing owner {get;set;}
        @AuraEnabled
        public String ownerid {get;set;}
        @AuraEnabled
        public String ownername {get;set;}
        
        public ActivityWrapper(){}
        
        public Integer compareTo(Object compareTo) {
            ActivityWrapper compareToEmp = (ActivityWrapper)compareTo;
            if (activityDate == compareToEmp.activityDate) return 0;
            if (activityDate < compareToEmp.activityDate) return 1;
            return -1;        
        }
        
    }
    
    public class Thing {
        
        @AuraEnabled
        public String id {get;set;}
        @AuraEnabled
        public String name {get;set;}
        
        public Thing(String id, String name){
            this.id = id;
            this.name = name;
        }
        
    }
    
}