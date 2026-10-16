/**
 * @description : LWC controller for egGprInterface component
 */
public with sharing class egGprInterfaceController {

    static final String PUBLISH_STATUS = 'Published';
    static final String DRAFT_STATUS = 'Draft';
    
    @AuraEnabled (cacheable=true)
    public static Object getOptions(){
        List<Object> countries = new List<Object>();
        countries.add(new Map<String,String>{
            'label' => ''
            , 'value' => ''
        });
        for(Library__c p :[SELECT Id, Name 
                           FROM Library__c 
                           WHERE RecordType.DeveloperName = 'DistributionList' AND Active__c = true
                           WITH SECURITY_ENFORCED ORDER BY Name Asc LIMIT: Limits.getLimitQueryRows()  ]){
            countries.add(new Map<String,String>{
                'label' => p.Name
                , 'value' => p.Id
            });
        }

        return countries;
    }

    @AuraEnabled
    public static void saveCountryRating(Country_Rating__c countryRating){
        try{
           //Find Status of Existing Rating record
           List<Country_Rating__c> countryRatings = [SELECT 
                                                        Id, Status__c 
                                                    FROM 
                                                        Country_Rating__c 
                                                    WHERE 
                                                        Id =:countryRating.Id 
                                                    With SECURITY_ENFORCED];
           if(! countryRatings.isEmpty() && countryRatings[0].Status__c == PUBLISH_STATUS){
                countryRating = countryRating.clone(false, true, false, false);
                insert countryRating;
           }else{
                upsert countryRating;
           }
            
        }catch(Exception ex){
            throw new AuraHandledException('Something went wrong: ' + ex.getMessage());    
        }
    }


    @AuraEnabled
    public static Country_Rating__c getCountryRating(Integer month, Integer year, String librabryId){
        List<Country_Rating__c> countryRatings = [SELECT 
                                                Economic_Policy_Macro_Impact_6_Months__c,Economic_Policy_Macro_Outlook_6_month__c,Economic_Policy_Macro__c,Gov_Stability_Cohesion_Impact_6_Months__c
                                                ,Gov_Stability_Cohesion_Outlook_6_Months__c,Gov_Stability_Cohesion__c,Id,Investment_Policy_Impact_6_months__c,Investment_Policy_Outlook_6_months__c
                                                ,Investment_Policy__c,Library__c,Name,Overview__c,Period__c
                                                ,Publish_Date__c,Security_Impact_6_Months__c,Security_Outlook_6_months__c,Security__c,Social_Stability_Impact_6_Months__c
                                                ,Social_Stability_Outlook_6_months__c,Social_Stability__c,Structural_Weight_1__c,Structural_Weight_2__c,Structural_Weight_3__c
                                                ,Structural_Weight_4__c,Structural_Weight_5__c,Structural_Weight_6__c,Structural_Weight_7__c,Structural_Weight_8__c,Structural_Weight_9__c
                                                ,Structural_Weight_10__c,Economic_Policy_Macro_Impact_24_Months__c,Economic_Policy_Macro_Outlook_24_month__c 
                                                ,Gov_Stability_Cohesion_Outlook_24_Months__c,Gov_Stability_Cohesion_Impact_24_Months__c,Social_Stability_Outlook_24_months__c
                                                ,Social_Stability_Impact_24_Months__c,Security_Outlook_24_months__c,Security_Impact_24_Months__c,Investment_Policy_Outlook_24_months__c
                                                ,Investment_Policy_Impact_24_months__c, Past_Period__c, Political_Trajectory_6_Months__c, Political_Trajectory_24_Months__c
                                                ,Raw_Score_6_Months__c, Raw_Score_24_Months__c, Status__c,Year__c,Month__c, LastModifiedDate
                                            FROM 
                                                Country_Rating__c
                                            WHERE 
                                                Library__c =:librabryId AND  Month__c = :month AND Year__c =:year
                                                With SECURITY_ENFORCED
                                                Order By LastModifiedDate Desc
                                                Limit 1]; 
        
        
        Country_Rating__c  countryRating = (countryRatings.isEmpty() 
            ? new Country_Rating__c(
                    Month__c = month
                    , year__c = year
                    , Status__c = 'New'
                    , Publish_Date__c = Date.Today()
                    , Library__c = librabryId
                    , Economic_Policy_Macro__c = 0
                    , Gov_Stability_Cohesion__c = 0
                    , Political_Trajectory_6_Months__c = 'Neutral'
                    , Political_Trajectory_24_Months__c = 'Neutral'
                    , Economic_Policy_Macro_Impact_6_Months__c = 'Neutral'
                    , Economic_Policy_Macro_Outlook_6_month__c = 'Neutral'
                    , Economic_Policy_Macro_Impact_24_Months__c = 'Neutral'
                    , Economic_Policy_Macro_Outlook_24_month__c = 'Neutral'
                    , Gov_Stability_Cohesion_Impact_6_Months__c = 'Neutral'
                    , Gov_Stability_Cohesion_Outlook_6_Months__c = 'Neutral'
                    , Gov_Stability_Cohesion_Impact_24_Months__c = 'Neutral'
                    , Gov_Stability_Cohesion_Outlook_24_Months__c = 'Neutral'
                    , Investment_Policy_Impact_6_months__c = 'Neutral'
                    , Investment_Policy_Outlook_6_months__c = 'Neutral'
                    , Investment_Policy_Impact_24_months__c = 'Neutral'
                    , Investment_Policy_Outlook_24_months__c = 'Neutral'
                    , Investment_Policy__c = 0
                    , Security_Impact_6_Months__c = 'Neutral' 
                    , Security_Outlook_6_months__c = 'Neutral' 
                    , Security_Impact_24_Months__c = 'Neutral' 
                    , Security_Outlook_24_months__c = 'Neutral' 
                    , Security__c= 0
                    , Social_Stability_Impact_6_Months__c = 'Neutral'
                    , Social_Stability_Outlook_6_months__c= 'Neutral'
                    , Social_Stability_Impact_24_Months__c = 'Neutral'
                    , Social_Stability_Outlook_24_months__c= 'Neutral'
                    , Social_Stability__c = 0
                    , Structural_Weight_1__c = '0'
                    , Structural_Weight_2__c = '0'
                    , Structural_Weight_3__c = '0'
                    , Structural_Weight_4__c = '0'
                    , Structural_Weight_5__c = '0'
                    , Structural_Weight_6__c = '0'
                    , Structural_Weight_7__c = '0'
                    , Structural_Weight_8__c = '0'
                    , Structural_Weight_9__c = '0'                    
                    , Structural_Weight_10__c = '0') 
            : countryRatings[0]);

        if(countryRating.Status__c == PUBLISH_STATUS){
            countryRating = countryRating.clone(false, true, false, false);
            //countryRating.Status__c = DRAFT_STATUS;
        }
        return countryRating;
    }
}