import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

import getPoliticalRiskAnalysesApex from "@salesforce/apex/ClientPortal_RiskDashboard_Ctlr.getPoliticalRiskAnalysesApex";
import getPoliticalRiskAnalysisApex from "@salesforce/apex/ClientPortal_RiskDashboard_Ctlr.getPoliticalRiskAnalysisApex";
import getHighriskSignpostsApex from "@salesforce/apex/ClientPortal_RiskDashboard_Ctlr.getHighriskSignpostsApex";
import getRegionalAnalysisApex from "@salesforce/apex/ClientPortal_RiskDashboard_Ctlr.getRegionalAnalysisApex";

import ClientPortal from '@salesforce/resourceUrl/ClientPortal';

export default class ClientPortal_RiskDashboard extends NavigationMixin(LightningElement) {

    //Tracked
    @track menuIsOpen = false;
    @track politicalRiskAnalysesByYear = [];
    @track isLoading = true;
    @track isWorking = true;
    @track selectedPoliticalRiskAnalysis;
    @track selectedSection;
    @track selectedRegionalAnalysis;

    //Private
    hasRendered = false; //Only initialize of first render
    urlStateParameters = {};

    //Wire
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if(currentPageReference){
          this.urlStateParameters = currentPageReference.state;
          this.initComponent();
       }
    }

    //UI Getters
    get noDashboards() {
        return !this.isLoading && !this.isWorking && !this.selectedPoliticalRiskAnalysis && (!this.politicalRiskAnalysesByYear || this.politicalRiskAnalysesByYear.length==0);
    } 
    get getMenuClass() {
        return 'political-risk-menu slds-p-around_small' + ((this.menuIsOpen) ? ' menu-is-open' : '');
    }    
    get getContentClass() {
        return 'political-risk-content' + ((this.menuIsOpen) ? ' menu-is-open' : '');
    }    
    get sectionIsExecutiveSummary() {
        return (this.selectedSection=='executiveSummary');
    }    
    get sectionIsGlossary() {
        return (this.selectedSection=='glossary');
    }    
    get sectionIsNetAssessment() {
        return (this.selectedSection=='netAssessment');
    }    
    get sectionIsBasecases() {
        return (this.selectedSection=='basecases');
    }    
    get sectionIsHeatmap() {
        return (this.selectedSection=='heatmap');
    }    
    get sectionIsHighrisk() {
        return (this.selectedSection=='highrisk');
    }    
    get sectionIsRegionalAnalysis() {
        return (this.selectedSection=='regionalAnalysis');
    }    
    get pdfUrl(){
        //switch this to ?id=politicalRiskAnalysisRecordId
        return '/clientportal/RiskDashboardPDF?id=' + this.selectedPoliticalRiskAnalysis.Id;
    }
    get isFullSubscriber(){
        return (this.selectedPoliticalRiskAnalysis?.Regional_Analysis__r?.length > 1);
    }
    get landingSection() {
        return (this.isFullSubscriber) ? 'executiveSummary' : 'glossary';
    }

    connectedCallback() {
        //this.initComponent(); //doing this in page change @wire because init wasn't happening after navigation via mixin
    }

    //Initialize Component
    initComponent = async () => { 
        this.isLoading = true;
        this.isWorking = true;

        let id = this.urlStateParameters.id;
        let hash = (document.URL && document.URL.indexOf('#')>-1) ? document.URL.split('#')[1] : null;
        let section = this.urlStateParameters.section || this.landingSection;

        if(id){
            //get selected political risk analysis...
            this.menuIsOpen = true;
            
            getPoliticalRiskAnalysisApex({politicalRiskAnalysisId: id})
            .then((selectedPoliticalRiskAnalysis) => {
                console.log('success', selectedPoliticalRiskAnalysis)
                //Success

                selectedPoliticalRiskAnalysis.hasExecutiveSummarySegments = false;
                selectedPoliticalRiskAnalysis.hasBasecases = false;
                selectedPoliticalRiskAnalysis.highriskSignposts = null;

                for(let regionalAnalysis of selectedPoliticalRiskAnalysis.Regional_Analysis__r){
                    regionalAnalysis = this.prepareRegionalAnalysis(regionalAnalysis);
                    if(regionalAnalysis.Executive_Summary_Segment_for_Region__c) selectedPoliticalRiskAnalysis.hasExecutiveSummarySegments = true;
                    if(regionalAnalysis.analysisDepthBasecase) selectedPoliticalRiskAnalysis.hasBasecases = true;
                }

                this.selectedPoliticalRiskAnalysis = selectedPoliticalRiskAnalysis;
                console.log('selectedPoliticalRiskAnalysis', selectedPoliticalRiskAnalysis)

                section = this.urlStateParameters.section || this.landingSection;

                console.log('section', section);

                if(section){
                    if(section=='executiveSummary' || section=='glossary' || section=='netAssessment' || section=='heatmap' || section=='basecases'){
                        this.selectedSection = section;
                        this.isLoading = false;
                    } else if(section=='highrisk'){
                        this.selectedSection = 'highrisk';
                        if(id){
                            getHighriskSignpostsApex({politicalRiskAnalysisId: id})
                            .then((highriskSignposts) => {
                                //Success, prepare high risk signposts...
                                if(highriskSignposts && highriskSignposts.length>0){
                                    this.selectedPoliticalRiskAnalysis.highriskSignposts = this.prepareSignposts(highriskSignposts);
                                } else {
                                    this.selectedPoliticalRiskAnalysis.highriskSignposts = null;
                                }
                            })
                            .catch((e) => {
                                //Error
                            })
                            .finally(() => {
                                this.isLoading = false;
                                this.isWorking = false;
                            });           
                        }
                    } else { //regional analysis Region Name
                        let regionalAnalysisId;

                        let regionName = section.replace(/([A-Z])/g, ' $1').replace(/^./, function(str){ return str.toUpperCase(); });
                        for(let regionalAnalysis of selectedPoliticalRiskAnalysis.Regional_Analysis__r){
                            if(regionalAnalysis.Region__r.Name==regionName){
                                regionalAnalysisId = regionalAnalysis.Id;
                                break;
                            }
                        }
        
                        this.selectedSection = 'regionalAnalysis';
                        if(regionalAnalysisId){
                            getRegionalAnalysisApex({regionalAnalysisId: regionalAnalysisId})
                            .then((regionalAnalysis) => {
                                //Success
                                this.selectedRegionalAnalysis = this.prepareRegionalAnalysis(regionalAnalysis)
                            })
                            .catch((e) => {
                                //Error
                            })
                            .finally(() => {
                                this.isLoading = false;
                                this.isWorking = false;
                            });           
                        }
                    }
                } else {
                    this.isLoading = false;
                    this.isWorking = false;
                }
            })
            .catch((e) => {
                //Error
            })
            .finally(() => {
                this.isWorking = false;
            });            
        } else {
            //get all political risk analyses...
            getPoliticalRiskAnalysesApex()
            .then((politicalRiskAnalyses) => {
                //Success
                console.log('getPoliticalRiskAnalysesApex: ', politicalRiskAnalyses);

                let politicalRiskAnalysesByYear = [];

                if(politicalRiskAnalyses && politicalRiskAnalyses.length>0){
                    let currentYear = politicalRiskAnalyses[0].Year__c;
                    let currentYearAnalyses = [];
                    let i = 0;                
                    for(let politicalRiskAnalysis of politicalRiskAnalyses){
                        if(politicalRiskAnalysis.Year__c==currentYear){
                            currentYearAnalyses.push(politicalRiskAnalysis);
                        } else {
                            //wrap up current year map...
                            politicalRiskAnalysesByYear.push({key: currentYear, list: currentYearAnalyses});
                            //reset for next year grouping...
                            currentYear = politicalRiskAnalysis.Year__c;
                            currentYearAnalyses = [];
                            currentYearAnalyses.push(politicalRiskAnalysis);
                        }     
                        if(i==politicalRiskAnalyses.length-1){
                            //last item, now change detection on next iteration, push now...
                            politicalRiskAnalysesByYear.push({key: currentYear, list: currentYearAnalyses});
                        }                        
                        i++;               
                    }

                    console.log('politicalRiskAnalysesByYear: ', politicalRiskAnalysesByYear);
                    this.politicalRiskAnalysesByYear = politicalRiskAnalysesByYear;
                } else {
                    //no analyses, do something with message
                }

                this.isWorking = false;
                this.isLoading = false;
            })
            .catch((e) => {
                //Error
                this.isWorking = false;
                this.isLoading = false;
            }); 

            setTimeout(() => {
                this.menuIsOpen = true;
            }, 100)
        }
    }

    navigate= async (event) => { 
        this.isWorking = true;

        try{
            this.template.querySelector('.top').scrollIntoView({behavior: "auto", block: "start", inline: "nearest"});
        } catch(e){}

        let target = event.currentTarget.dataset.target;
        let id = event.currentTarget.dataset.id;
        let index = event.currentTarget.dataset.index;

        console.log('---navigate: ', target, id, index);

        if(target==null && index==null){
            //navigate to root of political-risk-dashboard...
            this.selectedPoliticalRiskAnalysis = null;
            this.selectedSection = this.landingSection;
            
            let page = 'Political_Risk_Dashboard__c';
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: page
                }
            });
        } else if(target=='politicalRiskAnalysis' && index!=null){
            //navigate to a specific analysis...
            this.selectedPoliticalRiskAnalysis = null;
            this.selectedSection = this.landingSection;

            let page = 'Political_Risk_Dashboard__c';
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: page
                },
                state: {
                    id: id
                }
            });
        } else if(target=='regionalAnalysis' && index!=null){
            //add section hash...
            this.selectedSection = 'regionalAnalysis';
            let section = this.selectedPoliticalRiskAnalysis.Regional_Analysis__r[index].Region__r.Name;
            //convert to camelCase...
            section = section.replace(/[-_\s.]+(.)?/g, (_, c) => c ? c.toUpperCase() : '');
            section = section.substr(0, 1).toLowerCase() + section.substr(1);

            let page = 'Political_Risk_Dashboard__c';
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: page
                },
                state: {
                    id: id,
                    section: section
                }
            });
        } else {
            //add section hash...
            this.selectedSection = target;
            let section = target;
            let page = 'Political_Risk_Dashboard__c';
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: page
                },
                state: {
                    id: id,
                    section: section
                }
            });
        }

        this.isWorking = false;
    }

    prepareSignposts(signposts){
        if(signposts && signposts.length>0){
            for(let signpost of signposts){
                let iconPrefix = (signpost.Positive_or_negative_for_risk__c=='Positive') ? '' : 'r';

                //prepare icons for positive or negative for risk...
                if(signpost.Positive_or_negative_for_risk__c=='Negative'){
                    signpost.positiveOrNegativeForRisk__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
                } else if(signpost.Positive_or_negative_for_risk__c=='Positive'){
                    signpost.positiveOrNegativeForRisk__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
                }          
                signpost.positiveOrNegativeForRisk__iconUrl = ClientPortal + '/icons/sp' + signpost.Positive_or_negative_for_risk__c + '.png'; 

                //prepare icons for Likelihood...
                if(signpost.Likelihood__c=='Very low'){
                    signpost.likelihood__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
                } else if(signpost.Likelihood__c=='Low'){
                    signpost.likelihood__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
                } else if(signpost.Likelihood__c=='Medium'){
                    signpost.likelihood__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
                } else if(signpost.Likelihood__c=='High'){
                    signpost.likelihood__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
                } else if(signpost.Likelihood__c=='Very high'){
                    signpost.likelihood__iconClass = 'fal fa-arrow-circle-up'
                }          
                signpost.likelihood__iconUrl = ClientPortal + '/icons/' + iconPrefix + ((signpost.Likelihood__c=='Medium')?'sp':'') + signpost.Likelihood__c + '.png';

                //prepare icons for Impact...
                if(signpost.Impact__c=='Very low'){
                    signpost.impact__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
                } else if(signpost.Impact__c=='Low'){
                    signpost.impact__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
                } else if(signpost.Impact__c=='Medium'){
                    signpost.impact__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
                } else if(signpost.Impact__c=='High'){
                    signpost.impact__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
                } else if(signpost.Impact__c=='Very high'){
                    signpost.impact__iconClass = 'fal fa-arrow-circle-up'
                }          
                signpost.impact__iconUrl = ClientPortal + '/icons/' + iconPrefix + ((signpost.Impact__c=='Medium')?'sp':'') + signpost.Impact__c + '.png';
            }
        }

        return signposts;
    }

    prepareRegionalAnalysis(regionalAnalysis){
        if(regionalAnalysis){
            regionalAnalysis.analysisDepthFull = (regionalAnalysis.Analysis_Depth__c=='Full');
            regionalAnalysis.analysisDepthBasecase = (regionalAnalysis.Analysis_Depth__c=='Basecase');
            regionalAnalysis.newFormatForSignposts = false;

            if(regionalAnalysis.analysisDepthFull){
                if(regionalAnalysis.Key_Signposts__r && regionalAnalysis.Key_Signposts__r.length>0){
                    regionalAnalysis.Key_Signposts__r = this.prepareSignposts(regionalAnalysis.Key_Signposts__r);
                    for(let signpost of regionalAnalysis.Key_Signposts__r){
                        if(signpost.Impact__c){
                            regionalAnalysis.newFormatForSignposts = true;
                        } 
                    }
                }
            }

            if(regionalAnalysis.Short_term_political_trajectory__c=='Significantly negative'){
                regionalAnalysis.Short_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Short_term_political_trajectory__c=='Negative'){
                regionalAnalysis.Short_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
            } else if(regionalAnalysis.Short_term_political_trajectory__c=='Neutral'){
                regionalAnalysis.Short_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
            } else if(regionalAnalysis.Short_term_political_trajectory__c=='Positive'){
                regionalAnalysis.Short_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
            } else if(regionalAnalysis.Short_term_political_trajectory__c=='Significantly positive'){
                regionalAnalysis.Short_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up'
            }          
            regionalAnalysis.Short_term_political_trajectory__iconUrl = ClientPortal + '/icons/' + regionalAnalysis.Short_term_political_trajectory__c + '.png';

            if(regionalAnalysis.Long_term_political_trajectory__c=='Significantly negative'){
                regionalAnalysis.Long_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Long_term_political_trajectory__c=='Negative'){
                regionalAnalysis.Long_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
            } else if(regionalAnalysis.Long_term_political_trajectory__c=='Neutral'){
                regionalAnalysis.Long_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
            } else if(regionalAnalysis.Long_term_political_trajectory__c=='Positive'){
                regionalAnalysis.Long_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
            } else if(regionalAnalysis.Long_term_political_trajectory__c=='Significantly positive'){
                regionalAnalysis.Long_term_political_trajectory__iconClass = 'fal fa-arrow-circle-up'
            }          
            regionalAnalysis.Long_term_political_trajectory__iconUrl = ClientPortal + '/icons/' + regionalAnalysis.Long_term_political_trajectory__c + '.png';

            if(regionalAnalysis.Directional_change_since_last_month__c=='Significantly negative'){
                regionalAnalysis.Directional_change_since_last_month__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Directional_change_since_last_month__c=='Negative'){
                regionalAnalysis.Directional_change_since_last_month__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
            } else if(regionalAnalysis.Directional_change_since_last_month__c=='Neutral'){
                regionalAnalysis.Directional_change_since_last_month__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
            } else if(regionalAnalysis.Directional_change_since_last_month__c=='Positive'){
                regionalAnalysis.Directional_change_since_last_month__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
            } else if(regionalAnalysis.Directional_change_since_last_month__c=='Significantly positive'){
                regionalAnalysis.Directional_change_since_last_month__iconClass = 'fal fa-arrow-circle-up'
            }          
            regionalAnalysis.Directional_change_since_last_month__iconUrl = ClientPortal + '/icons/' + regionalAnalysis.Directional_change_since_last_month__c + '.png';

            if(regionalAnalysis.Estimated_risk_over_the_next_month__c=='Very low'){
                regionalAnalysis.Estimated_risk_over_the_next_month__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Estimated_risk_over_the_next_month__c=='Low'){
                regionalAnalysis.Estimated_risk_over_the_next_month__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
            } else if(regionalAnalysis.Estimated_risk_over_the_next_month__c=='Medium'){
                regionalAnalysis.Estimated_risk_over_the_next_month__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
            } else if(regionalAnalysis.Estimated_risk_over_the_next_month__c=='High'){
                regionalAnalysis.Estimated_risk_over_the_next_month__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
            } else if(regionalAnalysis.Estimated_risk_over_the_next_month__c=='Very high'){
                regionalAnalysis.Estimated_risk_over_the_next_month__iconClass = 'fal fa-arrow-circle-up'
            }          
            regionalAnalysis.Estimated_risk_over_the_next_month__iconUrl = ClientPortal + '/icons/r' + regionalAnalysis.Estimated_risk_over_the_next_month__c + '.png';

            if(regionalAnalysis.Basecase_confidence_level__c=='Low'){
                regionalAnalysis.Basecase_confidence_level__confidenceClass = 'Confidence low'
                regionalAnalysis.Basecase_confidence_level__iconClass = 'fal fa-tachometer-slowest'
            } else if(regionalAnalysis.Basecase_confidence_level__c=='Medium'){
                regionalAnalysis.Basecase_confidence_level__confidenceClass = 'Confidence medium'
                regionalAnalysis.Basecase_confidence_level__iconClass = 'fal fa-tachometer-average'
            } else if(regionalAnalysis.Basecase_confidence_level__c=='High'){
                regionalAnalysis.Basecase_confidence_level__confidenceClass = 'Confidence high'
                regionalAnalysis.Basecase_confidence_level__iconClass = 'fal fa-tachometer-fastest'
            }        
            regionalAnalysis.Basecase_confidence_level__iconUrl = ClientPortal + '/icons/' + regionalAnalysis.Basecase_confidence_level__c + '.png';

            if(regionalAnalysis.Risk_Change_Domestic_Stability__c=='Extremely negative'){
                regionalAnalysis.Risk_Change_Domestic_Stability__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Domestic_Stability__c=='Significantly negative'){
                regionalAnalysis.Risk_Change_Domestic_Stability__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Domestic_Stability__c=='Negative'){
                regionalAnalysis.Risk_Change_Domestic_Stability__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
            } else if(regionalAnalysis.Risk_Change_Domestic_Stability__c=='Neutral'){
                regionalAnalysis.Risk_Change_Domestic_Stability__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
            } else if(regionalAnalysis.Risk_Change_Domestic_Stability__c=='Positive'){
                regionalAnalysis.Risk_Change_Domestic_Stability__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
            } else if(regionalAnalysis.Risk_Change_Domestic_Stability__c=='Significantly positive'){
                regionalAnalysis.Risk_Change_Domestic_Stability__iconClass = 'fal fa-arrow-circle-up'
            } else if(regionalAnalysis.Risk_Change_Domestic_Stability__c=='Extremely positive'){
                regionalAnalysis.Risk_Change_Domestic_Stability__iconClass = 'fal fa-arrow-circle-up'
            }          
            regionalAnalysis.Risk_Change_Domestic_Stability__iconUrl = ClientPortal + '/icons/' + regionalAnalysis.Risk_Change_Domestic_Stability__c + '.png';
            regionalAnalysis.Risk_Change_Domestic_Stability__heatmapStyle = 'background-color: ' + regionalAnalysis.Risk_Color_Domestic_Stability__c + '!important;';

            if(regionalAnalysis.Risk_Change_Economy__c=='Extremely negative'){
                regionalAnalysis.Risk_Change_Economy__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Economy__c=='Significantly negative'){
                regionalAnalysis.Risk_Change_Economy__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Economy__c=='Negative'){
                regionalAnalysis.Risk_Change_Economy__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
            } else if(regionalAnalysis.Risk_Change_Economy__c=='Neutral'){
                regionalAnalysis.Risk_Change_Economy__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
            } else if(regionalAnalysis.Risk_Change_Economy__c=='Positive'){
                regionalAnalysis.Risk_Change_Economy__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
            } else if(regionalAnalysis.Risk_Change_Economy__c=='Significantly positive'){
                regionalAnalysis.Risk_Change_Economy__iconClass = 'fal fa-arrow-circle-up'
            } else if(regionalAnalysis.Risk_Change_Economy__c=='Extremely positive'){
                regionalAnalysis.Risk_Change_Economy__iconClass = 'fal fa-arrow-circle-up'
            }          
            regionalAnalysis.Risk_Change_Economy__iconUrl = ClientPortal + '/icons/' + regionalAnalysis.Risk_Change_Economy__c + '.png';
            regionalAnalysis.Risk_Change_Economy__heatmapStyle = 'background-color: ' + regionalAnalysis.Risk_Color_Economy__c + '!important;';

            if(regionalAnalysis.Risk_Change_Global_Position__c=='Extremely negative'){
                regionalAnalysis.Risk_Change_Global_Position__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Global_Position__c=='Significantly negative'){
                regionalAnalysis.Risk_Change_Global_Position__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Global_Position__c=='Negative'){
                regionalAnalysis.Risk_Change_Global_Position__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
            } else if(regionalAnalysis.Risk_Change_Global_Position__c=='Neutral'){
                regionalAnalysis.Risk_Change_Global_Position__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
            } else if(regionalAnalysis.Risk_Change_Global_Position__c=='Positive'){
                regionalAnalysis.Risk_Change_Global_Position__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
            } else if(regionalAnalysis.Risk_Change_Global_Position__c=='Significantly positive'){
                regionalAnalysis.Risk_Change_Global_Position__iconClass = 'fal fa-arrow-circle-up'
            } else if(regionalAnalysis.Risk_Change_Global_Position__c=='Extremely positive'){
                regionalAnalysis.Risk_Change_Global_Position__iconClass = 'fal fa-arrow-circle-up'
            }          
            regionalAnalysis.Risk_Change_Global_Position__iconUrl = ClientPortal + '/icons/' + regionalAnalysis.Risk_Change_Global_Position__c + '.png';
            regionalAnalysis.Risk_Change_Global_Position__heatmapStyle = 'background-color: ' + regionalAnalysis.Risk_Color_Global_Position__c + '!important;';

            if(regionalAnalysis.Risk_Change_Leadership_Intent__c=='Extremely negative'){
                regionalAnalysis.Risk_Change_Leadership_Intent__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Leadership_Intent__c=='Significantly negative'){
                regionalAnalysis.Risk_Change_Leadership_Intent__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Leadership_Intent__c=='Negative'){
                regionalAnalysis.Risk_Change_Leadership_Intent__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
            } else if(regionalAnalysis.Risk_Change_Leadership_Intent__c=='Neutral'){
                regionalAnalysis.Risk_Change_Leadership_Intent__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
            } else if(regionalAnalysis.Risk_Change_Leadership_Intent__c=='Positive'){
                regionalAnalysis.Risk_Change_Leadership_Intent__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
            } else if(regionalAnalysis.Risk_Change_Leadership_Intent__c=='Significantly positive'){
                regionalAnalysis.Risk_Change_Leadership_Intent__iconClass = 'fal fa-arrow-circle-up'
            } else if(regionalAnalysis.Risk_Change_Leadership_Intent__c=='Extremely positive'){
                regionalAnalysis.Risk_Change_Leadership_Intent__iconClass = 'fal fa-arrow-circle-up'
            }          
            regionalAnalysis.Risk_Change_Leadership_Intent__iconUrl = ClientPortal + '/icons/' + regionalAnalysis.Risk_Change_Leadership_Intent__c + '.png';
            regionalAnalysis.Risk_Change_Leadership_Intent__heatmapStyle = 'background-color: ' + regionalAnalysis.Risk_Color_Leadership_Intent__c + '!important;';

            if(regionalAnalysis.Risk_Change_Security__c=='Extremely negative'){
                regionalAnalysis.Risk_Change_Security__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Security__c=='Significantly negative'){
                regionalAnalysis.Risk_Change_Security__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
            } else if(regionalAnalysis.Risk_Change_Security__c=='Negative'){
                regionalAnalysis.Risk_Change_Security__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
            } else if(regionalAnalysis.Risk_Change_Security__c=='Neutral'){
                regionalAnalysis.Risk_Change_Security__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
            } else if(regionalAnalysis.Risk_Change_Security__c=='Positive'){
                regionalAnalysis.Risk_Change_Security__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
            } else if(regionalAnalysis.Risk_Change_Security__c=='Significantly positive'){
                regionalAnalysis.Risk_Change_Security__iconClass = 'fal fa-arrow-circle-up'
            } else if(regionalAnalysis.Risk_Change_Security__c=='Extremely positive'){
                regionalAnalysis.Risk_Change_Security__iconClass = 'fal fa-arrow-circle-up'
            }          
            regionalAnalysis.Risk_Change_Security__iconUrl = ClientPortal + '/icons/' + regionalAnalysis.Risk_Change_Security__c + '.png';
            regionalAnalysis.Risk_Change_Security__heatmapStyle = 'background-color: ' + regionalAnalysis.Risk_Color_Security__c + '!important;';

            if(regionalAnalysis.Key_Analytic_Assumptions__r && regionalAnalysis.Key_Analytic_Assumptions__r.length>0){
                for(let assumption of regionalAnalysis.Key_Analytic_Assumptions__r){
                    assumption.isNew = (assumption.New_KAA__c=='Yes');
                    assumption.class = (assumption.New_KAA__c=='Yes') ? 'is-new' : '';
                }
            }

            if(regionalAnalysis.Key_Events__r && regionalAnalysis.Key_Events__r.length>0){
                for(let event of regionalAnalysis.Key_Events__r){
                    if(event.Probable_impact_on_risk_negative_higher__c=='Significantly negative'){
                        event.Probable_impact_on_risk_negative_higher__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
                    } else if(event.Probable_impact_on_risk_negative_higher__c=='Negative'){
                        event.Probable_impact_on_risk_negative_higher__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
                    } else if(event.Probable_impact_on_risk_negative_higher__c=='Neutral'){
                        event.Probable_impact_on_risk_negative_higher__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
                    } else if(event.Probable_impact_on_risk_negative_higher__c=='Positive'){
                        event.Probable_impact_on_risk_negative_higher__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
                    } else if(event.Probable_impact_on_risk_negative_higher__c=='Significantly positive'){
                        event.Probable_impact_on_risk_negative_higher__iconClass = 'fal fa-arrow-circle-up'
                    }          
                    event.Probable_impact_on_risk_negative_higher__iconUrl = ClientPortal + '/icons/' + event.Probable_impact_on_risk_negative_higher__c + '.png';
                }
            }

            if(regionalAnalysis.Key_Signposts__r && regionalAnalysis.Key_Signposts__r.length>0){
                for(let signpost of regionalAnalysis.Key_Signposts__r){
                    if(signpost.Likely_impact__c=='Very low'){
                        signpost.Likely_impact__iconClass = 'fal fa-arrow-circle-up fa-rotate-180'
                    } else if(signpost.Likely_impact__c=='Low'){
                        signpost.Likely_impact__iconClass = 'fal fa-arrow-circle-up fa-rotate-135'
                    } else if(signpost.Likely_impact__c=='Medium'){
                        signpost.Likely_impact__iconClass = 'fal fa-arrow-circle-up fa-rotate-90'
                    } else if(signpost.Likely_impact__c=='High'){
                        signpost.Likely_impact__iconClass = 'fal fa-arrow-circle-up fa-rotate-45'
                    } else if(signpost.Likely_impact__c=='Very high'){
                        signpost.Likely_impact__iconClass = 'fal fa-arrow-circle-up'
                    }          
                    signpost.Likely_impact__iconUrl = ClientPortal + '/icons/r' + signpost.Likely_impact__c + '.png';
                }
            }
        }
        
        return regionalAnalysis;
    }
}