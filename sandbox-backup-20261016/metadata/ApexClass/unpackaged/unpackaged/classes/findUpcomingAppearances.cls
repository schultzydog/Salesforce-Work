/**
 * Controller class for EG_in_the_Media VF Component, This fetchs media apperances and categorized them into different categories  
 **/
public class findUpcomingAppearances {
    //Upcoming > Upcoming__c= true
    //public List<Media_Appearance__c> upcomings{get;set;}
    //BroadCast > Upcoming__c= true AND Type__c == 'Broadcast'
    //public List<Media_Appearance__c> broadcasts{get; private set;}
    //Print/Online > Upcoming__c= true AND Type__c == 'Print/Online'
    //public List<Media_Appearance__c> printOnlines{get;private set;}
    public List<Media_Appearance__c> includes{get;private set;}
    
    public findUpcomingAppearances() {
        //Initiate list
        //upcomings = new List<Media_Appearance__c>();
        //broadcasts = new List<Media_Appearance__c>();
        //printOnlines = new List<Media_Appearance__c>();
        includes = new List<Media_Appearance__c>();
        
        //Find All Media Apperance to include in the newsletter
        //Fetch only Broadcast and Print/Online - Due to Sort Order differences
        //this.prepareList(' Upcoming_news__c = false' , 'Sector_Region__c DESC NULLS First, Date__c DESC Nulls Last ');
       //Fetch only Broadcast and Print/Online - Due to Sort Order differences
        //this.prepareList(' Upcoming_news__c = true' , 'Sector_Region__c ASC NULLS First, Date__c ASC Nulls Last ');
        includes = [SELECT Id, Source__c, Sector_Region__c, Headline__c, Author_Participant_text_line__c, Account__r.Name, Outlet__c, Appearance_Summary__c,Date__c,Type__c,Upcoming_news__c,Time_text__c 
                     FROM Media_Appearance__c WHERE Include_in_next_send__c = TRUE Order By Sector_Region__c DESC NULLS First, Date__c DESC Nulls Last];
        
    }
    /*
    //Prepare list of Media appearance
    private void prepareList(String queryFilter, String sortOrder){
        //String query = 'SELECT Id, Source__c, Sector_Region__c, Headline__c, Author_Participant_text_line__c, Account__r.Name, Outlet__c, Appearance_Summary__c,Date__c,Type__c,Upcoming_news__c,Time_text__c ' 
        //                + ' FROM Media_Appearance__c';
        //query += ' WHERE Include_in_next_send__c = TRUE AND ' + queryFilter + ' Order By ' + sortOrder;
        String query = 'SELECT Id, Source__c, Sector_Region__c, Headline__c, Author_Participant_text_line__c, Account__r.Name, Outlet__c, Appearance_Summary__c,Date__c,Type__c,Upcoming_news__c,Time_text__c ' 
             + ' FROM Media_Appearance__c WHERE Include_in_next_send__c = TRUE Order By Sector_Region__c DESC NULLS First, Date__c DESC Nulls Last'; 
        for(Media_Appearance__c news: (List<Media_Appearance__c>)Database.query(query)){
            if(news.Upcoming_news__c == true){
                //upcomings.add(news);
            }else if(news.Type__c == 'Broadcast'){
                //broadcasts.add(news);            
            }else if(news.Type__c == 'Print/Online'){
               //printOnlines.add(news);            
            }
            includes.add(news);
            
         
        }
    }
    */
/*
    //Send Email- Flow Method
    @InvocableMethod(label='EG in media email' description='EG in media email' category='EG in Media')
    public static void sendEmail(List<String> toAddresses) {
        //Email template
        EG_In_Media__mdt  setting = EG_In_Media__mdt.getInstance('Email_Template');
        EmailTemplate et = [SELECT id from EmailTemplate where developername=:setting.value__c];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setTargetObjectId(Userinfo.getUserId());
        mail.setSaveAsActivity(false);
        mail.setTemplateId(et.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
*/
}