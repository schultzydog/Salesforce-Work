/**
 *  @description - Controller class for RiskDashboard PDF VF Page 
 **/
public with sharing class ClientPortal_RiskDashboardPDF_Ctlr {
    
    public String recordId;//Political Risk Analysis Id  

    public String month {get; private set;}
    public String year {get; private set;}
    public string fileName {get; private set;}
    public user runningUser {get;private set;}

    public Political_Risk_Analysis__c politicalRiskAnaysis {get; private set;}
    public List<Key_Signpost__c> highriskSignposts {get; private set;}    
    public List<Regional_Analysis__c> regionalAnalyses {get; private set;}
    public Boolean isFullSubscriber {get; private set;}
    public Boolean hasBasecases {get; private set;}

    public String fontSalesforceSansBoldUrl {public get; private set;}
    public String fontSalesforceSansBoldItalicUrl {public get; private set;}
    public String fontSalesforceSansItalicUrl {public get; private set;}
    public String fontSalesforceSansLightUrl {public get; private set;}
    public String fontSalesforceSansLightItalicUrl {public get; private set;}
    public String fontSalesforceSansRegularUrl {public get; private set;}
    public String fontSalesforceSansThinUrl {public get; private set;}
    public String fontSalesforceSansThinItalicUrl {public get; private set;}

    public ClientPortal_RiskDashboardPDF_Ctlr(ApexPages.StandardController stdCon) {
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/clientportal/';
        system.debug('baseUrl ' + baseUrl);
            
        fontSalesforceSansBoldUrl = baseUrl + 'resource/Fonts_SalesforceSans/SalesforceSans-Bold.ttf';
        fontSalesforceSansBoldItalicUrl = baseUrl + 'resource/Fonts_SalesforceSans/SalesforceSans-BoldItalic.ttf';
        fontSalesforceSansItalicUrl = baseUrl + 'resource/Fonts_SalesforceSans/SalesforceSans-Italic.ttf';
        fontSalesforceSansLightUrl = baseUrl + 'resource/Fonts_SalesforceSans/SalesforceSans-Light.ttf';
        fontSalesforceSansLightItalicUrl = baseUrl + 'resource/Fonts_SalesforceSans/SalesforceSans-LightItalic.ttf';
        fontSalesforceSansRegularUrl = baseUrl + 'resource/Fonts_SalesforceSans/SalesforceSans-Regular.ttf';
        fontSalesforceSansThinUrl = baseUrl + 'resource/Fonts_SalesforceSans/SalesforceSans-Thin.ttf';
        fontSalesforceSansThinItalicUrl = baseUrl + 'resource/Fonts_SalesforceSans/SalesforceSans-ThinItalic.ttf';
        
        this.recordId = stdCon.getId();

        this.politicalRiskAnaysis = ClientPortal_RiskDashboard_Ctlr.getPoliticalRiskAnalysisApex(this.recordId);
        if(this.politicalRiskAnaysis != null){
            this.highriskSignposts = ClientPortal_RiskDashboard_Ctlr.getHighriskSignpostsApex(this.politicalRiskAnaysis.Id);

            this.month = this.politicalRiskAnaysis.Month_Name__c;
            this.year = this.politicalRiskAnaysis.Year__c;
            this.regionalAnalyses = ClientPortal_RiskDashboard_Ctlr.getSubscribedRegionalAnalysesApex(this.recordId);
            this.isFullSubscriber = (this.regionalAnalyses!=null && this.regionalAnalyses.size()>1);
            this.hasBasecases = false;
            for(Regional_Analysis__c regionalAnalysis : this.regionalAnalyses){
                if(regionalAnalysis.Analysis_Depth__c=='Basecase') this.hasBasecases = true;
            }
            this.fileName = this.year + '-' + politicalRiskAnaysis.month__c + ' Eurasia Group Political Risk Dashboard ' + this.month + ' ' + this.year + '.pdf';
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=' + this.fileName);
        }
        //Get Running user details
        runningUser = [SELECT Id, ContactId, Contact.AccountId, Contact.Account.Account_Name_for_Risk_Dashboard_PDF__c FROM User WHERE Id = :UserInfo.getUserId()];//Account_Name_for_Risk_Dashboard_PDF__c
    }


}