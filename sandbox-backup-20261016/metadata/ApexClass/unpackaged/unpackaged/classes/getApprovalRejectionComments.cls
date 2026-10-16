/* 
code coverage provided by opportunityHandlerTest
*/
public class getApprovalRejectionComments {
  
    @InvocableMethod(label='Get Rejection Comments' description='returns the Comments value from the most recent approva Rejection.' category='Opportunity')   
    public static List<String> getRejectionComments(List<Opportunity> opps) {
        List<String> comments = New List<String>();
        List<ProcessInstance> pi = [SELECT ID, (SELECT comments FROM StepsAndWorkitems WHERE StepStatus = 'Rejected' LIMIT 1) FROM ProcessInstance 
                                       WHERE Status = 'Rejected' AND TargetObjectId = :opps[0].Id ORDER BY CreatedDate DESC NULLS FIRST LIMIT 1];
        
        //system.debug('### pi =  ' + pi);
        //system.debug('### + +pi[0].StepsAndWorkitems[0].Comments' + pi[0].StepsAndWorkitems[0].Comments);   
        
        if (pi.size() > 0 && pi[0].StepsAndWorkitems.size()> 0 && pi[0].StepsAndWorkitems[0].Comments != null) comments.add(pi[0].StepsAndWorkitems[0].Comments);
        return comments;
    }
}