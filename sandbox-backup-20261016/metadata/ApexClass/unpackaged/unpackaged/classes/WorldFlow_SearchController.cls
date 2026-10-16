/*
* LWC Controller for WorldFlow_Search LWC component
*/
public with sharing class WorldFlow_SearchController {


    public WorldFlow_SearchController() {
        contentType = ApexPages.currentPage().getParameters().get('type');
        if(String.isBlank(contentType)){
            contentType = 'html';
        }
    }

    
    public String contentType {get;set;}
    //PDF download action
    public String pdf{
        get{
            String pdfBlob;
        String documentCode = ApexPages.currentPage().getParameters().get('code');
        if(String.isNotBlank(documentCode)){
            pdfBlob =  EncodingUtil.Base64Encode(WorldFlow_ApiUtils.getInstance().getResearchFile(documentCode));

        }

        return pdfBlob;
        }
    }

    //PDF download action
    public String articleHTML{
        get{
            String article;
            String documentCode = ApexPages.currentPage().getParameters().get('code');
            if(String.isNotBlank(documentCode)){
                article =  WorldFlow_ApiUtils.getInstance().getResearchFileHTML(documentCode);
                article = article.replace('class="col-xs-4 bkgd-grey"', 'class="slds-col slds-size_1-of-1 slds-medium-size_12-of-12 slds-large-size_4-of-12"');
                article = article.replace('class="col-xs-8 top-row"', 'class="slds-col slds-size_1-of-1 slds-medium-size_12-of-12 slds-large-size_8-of-12"');
                article = article.replace('flex-basis: 66.667%;','');
                article = article.replace('max-width: 66.667%;','');
                article = article.replace('flex-basis: 33.333%;','');
                article = article.replace('max-width: 33.333%;','');
                
                article = article.replace('margin-top: 12em;','margin-top: 1em;');

            }

            return article;
        }
    }

    @Auraenabled(cacheable=true)
    public static Map<String,Object> getSearchParams(){
        Map<String,Object>  response;
        try {
            response = (Map<String, Object>) JSON.deserializeUntyped(WorldFlow_ApiUtils.getInstance().fetchSearchParameters());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return response;
    }


    @Auraenabled
    public static Map<String,Object> search(String searchTxt, List<String> regionCode, List<String> countryCode, List<String> tagCode, List<String> analystCode, integer index, String dateRange){
        Map<String,Object>  response;
        try {
            response = (Map<String, Object>) JSON.deserializeUntyped(
                                    WorldFlow_ApiUtils.getInstance()
                                        .searchResearchs(searchTxt, regionCode, countryCode, tagCode, analystCode,  25, index , dateRange)
                                    );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        //Date Range = 'AllDates', NewSubmissions

        return response;
    }

    

    @Auraenabled
    public static Object getResearchFile(String documentCode, String contentType){
        Object  response;
        try {
            if(contentType == 'HTML'){
                response = WorldFlow_ApiUtils.getInstance().getResearchFileHTML(documentCode);
            }else{
                response = EncodingUtil.Base64Encode(WorldFlow_ApiUtils.getInstance().getResearchFile(documentCode));//EncodingUtil.Base64Encode(W
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return response;
    }
}