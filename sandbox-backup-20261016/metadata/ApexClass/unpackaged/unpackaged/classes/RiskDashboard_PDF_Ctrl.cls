/**
 *  @description - Controller class for RiskDashboard PDF VF Page 
 **/
public without sharing class RiskDashboard_PDF_Ctrl {
    
    public String recordId;//Political Risk Analysis Id    
    public String month {get; private set;}
    public String year {get; private set;}
    public string fileName {get; private set;}

    public Political_Risk_Analysis__c politicalRiskAnaysis {get; private set;}
    public List<Regional_Analysis__c> regionalAnalyses {get; private set;}

    public RiskDashboard_PDF_Ctrl(ApexPages.StandardController stdCon) {

        this.recordId = stdCon.getId();
        this.politicalRiskAnaysis = ClientPortal_RiskDashboard_Ctlr.getPoliticalRiskAnalysisApex(this.recordId);
        if(this.politicalRiskAnaysis != null){
            this.month = this.politicalRiskAnaysis.Month_Name__c;
            this.year = this.politicalRiskAnaysis.Year__c;
            this.regionalAnalyses = ClientPortal_RiskDashboard_Ctlr.getSubscribedRegionalAnalysesApex(this.recordId);
            this.fileName = this.year + '-' + politicalRiskAnaysis.month__c + ' Eurasia Group Political Risk Dashboard ' + this.month + ' ' + this.year;
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=' + this.fileName);
        }
    }


}