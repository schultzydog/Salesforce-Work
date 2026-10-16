public without sharing class ClientPortal_RiskDashboard_Ctlr {
    
    @AuraEnabled(cacheable=false)
    public static List<Political_Risk_Analysis__c> getPoliticalRiskAnalysesApex(){
        List<Political_Risk_Analysis__c> politicalRiskAnayses = new List<Political_Risk_Analysis__c>();
        
        //access check... new simplified product entitlement check, if any subscribed library via account prefs, you get full access, though each dashboard only contains subscribed regions
        Set<Id> subscribedLibraryIds = getSubscribedLibraryIds();

        if(!subscribedLibraryIds.isEmpty()){ //not empty
            politicalRiskAnayses = [SELECT Id, Name, Month__c, Year__c, Month_Name__c
                                    FROM Political_Risk_Analysis__c
                                    WHERE Published_Date__c != NULL
                                    ORDER BY Year__c DESC, Month__c DESC, Published_Date__c DESC];
        } 

        return politicalRiskAnayses;
    }

    @AuraEnabled(cacheable=false)
    public static Political_Risk_Analysis__c getPoliticalRiskAnalysisApex(Id politicalRiskAnalysisId){
        //get a single political risk analysis with subscribed regional analysis records...
        Political_Risk_Analysis__c politicalRiskAnaysis;

        //access check...
        Set<Id> subscribedLibraryIds = getSubscribedLibraryIds();
        
        if(!subscribedLibraryIds.isEmpty()){
            //get full political risk analysis with subscribed libraries...
            politicalRiskAnaysis = [SELECT Id, Name, Month__c, Year__c, Month_Name__c, Executive_Summary__c, Glossary__c,
                                    (SELECT Id, Name, Region__r.Name, Region__r.Flag_image_URL__c, 
                                    Net_Assessment__c, Basecase__c, Analysis_Depth__c, Executive_Summary_Segment_for_Region__c,
                                    Short_term_political_trajectory__c, Long_term_political_trajectory__c,
                                    Directional_change_since_last_month__c, Basecase_confidence_level__c,
                                    Last_month_s_events_to_basecase__c, Estimated_risk_over_the_next_month__c,
                                    Risk_Change_Domestic_Stability__c, Risk_Change_Economy__c, 
                                    Risk_Change_Global_Position__c, Risk_Change_Leadership_Intent__c,
                                    Risk_Change_Security__c,
                                    Risk_Color_Domestic_Stability__c, Risk_Color_Economy__c, 
                                    Risk_Color_Global_Position__c, Risk_Color_Leadership_Intent__c,
                                    Risk_Color_Security__c
                                    FROM Regional_Analysis__r
                                    WHERE Region__c IN :subscribedLibraryIds 
                                    ORDER BY Region__r.Name)
                                    FROM Political_Risk_Analysis__c
                                    WHERE Id = :politicalRiskAnalysisId][0];
        } 

        return politicalRiskAnaysis;
    }

    @AuraEnabled(cacheable=false)
    public static List<Regional_Analysis__c> getSubscribedRegionalAnalysesApex(Id politicalRiskAnalysisId){
        //get regional analyses for a political risk analysis...        
        List<Regional_Analysis__c> regionalAnalyses;

        //access check...
        Set<Id> subscribedRegionIds = getSubscribedLibraryIds();

        if(!subscribedRegionIds.isEmpty()){
            regionalAnalyses = [SELECT Id, Name, Region__r.Name, Region__r.Flag_image_URL__c, 
                                Net_Assessment__c, Basecase__c, Analysis_Depth__c, Executive_Summary_Segment_for_Region__c,
                                Short_term_political_trajectory__c, Long_term_political_trajectory__c,
                                Directional_change_since_last_month__c, Basecase_confidence_level__c,
                                Last_month_s_events_to_basecase__c, Estimated_risk_over_the_next_month__c,
                                Risk_Change_Domestic_Stability__c, Risk_Change_Economy__c, 
                                Risk_Change_Global_Position__c, Risk_Change_Leadership_Intent__c,
                                Risk_Change_Security__c,
                                Risk_Color_Domestic_Stability__c, Risk_Color_Economy__c, 
                                Risk_Color_Global_Position__c, Risk_Color_Leadership_Intent__c,
                                Risk_Color_Security__c,
                                (SELECT Id, Name, Assumption__c, Category__c, New_KAA__c 
                                FROM Key_Analytic_Assumptions__r
                                ORDER BY New_KAA__c DESC, Sort_Order__c NULLS LAST, Category__c, CreatedDate DESC),
                                (SELECT Id, Name, Date_Text__c, Event__c, Category__c, 
                                Assessment_vs_key_analytic_assumptions__c, Probable_impact_on_risk_negative_higher__c
                                FROM Key_Events__r
                                ORDER BY Sort_Order__c NULLS LAST, Category__c, CreatedDate DESC),
                                (SELECT Id, Name, Event__c, Category__c, Likely_impact__c,
                                Regional_Analysis__r.Region__r.Name, Regional_Analysis__r.Region__r.Flag_image_URL__c, Likelihood__c, Impact__c, Positive_or_negative_for_risk__c
                                FROM Key_Signposts__r
                                ORDER BY Sort_Order__c NULLS LAST, Category__c, CreatedDate DESC)
                                FROM Regional_Analysis__c
                                WHERE Political_Risk_Analysis__c = :politicalRiskAnalysisId AND 
                                Region__c IN :subscribedRegionIds
                                ORDER BY Region__r.Name];
        }
    
        return regionalAnalyses;
    }


    @AuraEnabled(cacheable=false)
    public static List<Key_Signpost__c> getHighriskSignpostsApex(Id politicalRiskAnalysisId){ 
        Set<Id> subscribedRegionIds = getSubscribedLibraryIds();
        List<Key_Signpost__c> highriskSignposts = [SELECT Id, Name, Event__c, Category__c, Likely_impact__c,
                                                   Regional_Analysis__r.Region__r.Name, Regional_Analysis__r.Region__r.Flag_image_URL__c, Likelihood__c, Impact__c, Positive_or_negative_for_risk__c
                                                   FROM Key_Signpost__c
                                                   WHERE Regional_Analysis__r.Political_Risk_Analysis__c = :politicalRiskAnalysisId AND
                                                   (Impact__c = 'High' OR Impact__c = 'Very High') AND
                                                   Regional_Analysis__r.Region__c IN :subscribedRegionIds
                                                   ORDER BY Regional_Analysis__r.Region__r.Name, Impact__c DESC, Likelihood__c DESC, Sort_Order__c NULLS LAST, CreatedDate DESC];

        return highriskSignposts;
    }

    @AuraEnabled(cacheable=false)
    public static Regional_Analysis__c getRegionalAnalysisApex(Id regionalAnalysisId){
        //get an individual regional analysis...
        Regional_Analysis__c regionalAnalysis;

        //access check...
        Set<Id> subscribedRegionIds = getSubscribedLibraryIds();

        if(!subscribedRegionIds.isEmpty()){
            regionalAnalysis = [SELECT Id, Name, Political_Risk_Analysis__c, Region__r.Name, Region__r.Flag_image_URL__c, 
                                Net_Assessment__c, Basecase__c, Analysis_Depth__c, Executive_Summary_Segment_for_Region__c,
                                Short_term_political_trajectory__c, Long_term_political_trajectory__c,
                                Directional_change_since_last_month__c, Basecase_confidence_level__c,
                                Last_month_s_events_to_basecase__c, Estimated_risk_over_the_next_month__c,
                                Risk_Change_Domestic_Stability__c, Risk_Change_Economy__c, 
                                Risk_Change_Global_Position__c, Risk_Change_Leadership_Intent__c,
                                Risk_Change_Security__c,
                                Risk_Color_Domestic_Stability__c, Risk_Color_Economy__c, 
                                Risk_Color_Global_Position__c, Risk_Color_Leadership_Intent__c,
                                Risk_Color_Security__c,
                                (SELECT Id, Name, Assumption__c, Category__c, New_KAA__c 
                                FROM Key_Analytic_Assumptions__r
                                ORDER BY New_KAA__c DESC, Sort_Order__c NULLS LAST, Category__c, CreatedDate DESC),
                                (SELECT Id, Name, Date_Text__c, Event__c, Category__c, 
                                Assessment_vs_key_analytic_assumptions__c, Probable_impact_on_risk_negative_higher__c
                                FROM Key_Events__r
                                ORDER BY Sort_Order__c NULLS LAST, Category__c, CreatedDate DESC),
                                (SELECT Id, Name, Event__c, Category__c, Likely_impact__c, 
                                Regional_Analysis__r.Region__r.Name, Regional_Analysis__r.Region__r.Flag_image_URL__c, Likelihood__c, Impact__c, Positive_or_negative_for_risk__c
                                FROM Key_Signposts__r
                                ORDER BY Sort_Order__c NULLS LAST, Category__c, CreatedDate DESC)
                                FROM Regional_Analysis__c
                                WHERE Region__c IN :subscribedRegionIds AND
                                Id = :regionalAnalysisId][0];
        }

        return regionalAnalysis;
    }    
       
    private static Set<Id> getSubscribedLibraryIds(){
        //  As of 2/23/2023 it has been simplified to "if you have any Account Preference with Client_Portal_Political_Risk_Dashboard__c checked, you get full access to product
        //  But you will only be served regions that have this checkbox checked and the dashboard has published for any given month
        //  We no longer use Account_Preferences_by_Month__c and just go straight to Account_Preference__c.Client_Portal_Political_Risk_Dashboard__c checkbox
        //  (directed by Adam, 2/23/2023)
        
        Set<Id> subscribedLibraryIds = new Set<Id>();

        //get running user...
        User runningUser = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];

        if(runningUser.ContactId==null){
            //internal user...
            Map<Id, Library__c> allLibraries = new Map<Id, Library__c>([SELECT Id FROM Library__c]);
            subscribedLibraryIds = allLibraries.keySet();
        } else {
            //client portal user...
            List<Account_Preferences__c> accountPreferencesWithClientPortalPoliticalRiskDashboard = [SELECT Id, Library__c 
                                                                                                     FROM Account_Preferences__c
                                                                                                     WHERE Account__c = :runningUser.Contact.AccountId AND 
                                                                                                     Client_Portal_Political_Risk_Dashboard__c = TRUE];

            if(!accountPreferencesWithClientPortalPoliticalRiskDashboard.isEmpty()){
                for(Account_Preferences__c accountPreference : accountPreferencesWithClientPortalPoliticalRiskDashboard){
                    subscribedLibraryIds.add(accountPreference.Library__c);
                }
            }
        }

        return subscribedLibraryIds;
    }    
}