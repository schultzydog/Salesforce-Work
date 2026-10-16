public class invocable_getAnalystIds {
    @InvocableMethod(label='Get Analyst Ids')
    public static List<String> getAnalystUserIds(List<String> ids) { 
        
        List<String> analystEmails = new List<String>();
        List<String> analystIds = new List<String>();
        List<Deliverable__c> deliverables = [SELECT Analysts_Needed__c FROM Deliverable__c WHERE Id IN: ids];
        analystEmails = deliverables[0].Analysts_Needed__c.split(';');
        //system.debug('### analystEmails = ' + analystEmails);
        List<User> analysts = [SELECT Id FROM User WHERE Username IN: analystEmails];
        
        for (User u: analysts) {
            analystIds.add(u.Id);
        }
        //system.debug('### analystIds= ' + analystIds); 
        return analystIds;
    }
}