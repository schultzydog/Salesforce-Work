/**
 * @description       : Geopolitical Risk countryRating Interface
 * @last modified on  : 07-24-2023
**/
import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import getOptions from '@salesforce/apex/egGprInterfaceController.getOptions';
import getCountryRating from '@salesforce/apex/egGprInterfaceController.getCountryRating';
import saveCountryRating from '@salesforce/apex/egGprInterfaceController.saveCountryRating';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import IMPACT_FIELD from '@salesforce/schema/Country_Rating__c.Economic_Policy_Macro_Impact_6_Months__c';
import OUTLOOK_FIELD from '@salesforce/schema/Country_Rating__c.Economic_Policy_Macro_Outlook_6_month__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RatingCalculator } from './RatingCalculator';




export default class EgGprInterface extends NavigationMixin(LightningElement) {
    showWait = false;//To show progress spinner
    selectedMonth = ((new Date()).getMonth() + 1).toString() //Default to Current Month
    selectedYear = (new Date().getFullYear()).toString(); //Default to Current Year
    selectedCountry;
    monthOptions=[];
    yearOptions=[];
    countryOptions;//=[];

    countryRatingRecord;//countryRating Reocrd for the selected month, year and country
    overview;
    shortTermRawScore = 0;

    currentState = 'New';
    lastSaved = null;


    

    longTermRawScore = 0;

    get isNew(){
        return this.currentState == 'New';
    }

    get isDraft(){
        return this.currentState == 'Draft';
    }

    get isPublished(){
        return this.currentState == 'Published';
    }




    get shortTermRating(){
        let value = 'Neutral';
        if(this.shortTermRawScore < -0.5 ){
            value = 'Negative';
        }else if(this.shortTermRawScore > 0.5 ){
            value = 'Positive';
        }

        return value;
    }

    get longTermRating(){
        let value = 'Neutral';
        if(this.longTermRawScore < -0.5 ){
            value = 'Negative';
        }else if(this.longTermRawScore > 0.5 ){
            value = 'Positive';
        }
        return value;
    }


    get isReadOnly(){
        var date = new Date();
        var firstDay = new Date(date.getFullYear(), date.getMonth(), 1);
        var lastDay = new Date(this.selectedYear, this.selectedMonth , 0);
        return lastDay < firstDay;

    }


    //Wire methods 
    @wire(getOptions) countryOptions;

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: IMPACT_FIELD })
    impactOptions;

    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: OUTLOOK_FIELD })
    outlookOptions;
    
    //Initialization of component
    connectedCallback(){
        this.setMonthYearOptions();
    }

    //Set Month and Year Option list 
    setMonthYearOptions(){
        //For Month options ( 1 - 12)
        let index =1;
        Array.from({length: 12}, (item, i) => {
            return new Date(0, i).toLocaleString('en-US', {month: 'long'})
        })
        .forEach(m=>{
        this.monthOptions.push({
            'label' : m
            ,'value' : index.toString()
        });
        index++;
        });

        //For Year options (-1,0)
        const max = new Date().getFullYear() + 1;
        const min = max - 1;
        for (var i = max; i >= min; i--) {
            this.yearOptions.push({
                'label' : i.toString()
                ,'value' : i.toString()
            });
        }
    }


    //Handle Slider values
    handleWeightChange(event){
        const id = event.target.dataset.id;
        const val = event.target.value;
        this.sliders[id].value = val;
        this.calculateWeight();
    }

    //Handle Oulook & Impact drop down
    handleRiskChange(event){
        const id = event.target.dataset.id;
        const type = event.target.dataset.type;
        const name = event.target.name;
        const val = event.target.value;
        if(type =='shortTerm'){
            if(name == 'outlook'){
                this.countryRatingList[id].outlookShortTerm = val;
            }else{
                this.countryRatingList[id].impactShortTerm = val;
            }
        }else if(type =='longTerm'){
            if(name == 'outlook'){
                this.countryRatingList[id].outlookLongTerm = val;
            }else{
                this.countryRatingList[id].impactLongTerm = val;
            }
        }

        let _tmp = this.countryRatingList;
        this.countryRatingList = new Array();
        this.countryRatingList = _tmp;
        this.calculateWeight();
    }

    //Handle Events 
    handlePeriodChange(event){
        const val = event.detail.value;
        if(event.target.name == 'month'){
            this.selectedMonth = event.detail.value;
        }else if(event.target.name == 'year'){
            this.selectedYear = event.detail.value;
        }else if(event.target.name == 'country'){
            this.selectedCountry = event.detail.value;
        }

        console.dir(event.detail.value);
        //Invoke Find countryRating
        if(this.selectedCountry){
            this.findcountryRating();//
        }
    }

    //Handle Overview 
    handleOverview(event){
        this.countryRatingRecord.Overview__c = event.detail.value;
    }

    //Handle Submit method
    savecountryRating(isDraft){
        this.countryRatingRecord.Status__c = (isDraft ? 'Draft' : 'Published');
        
        this.showWait = true;
        this.bindcountryRatingRecord();
        saveCountryRating({
            'countryRating' : this.countryRatingRecord
        })
        .then((res)=>{
            this.showWait = false;
            const countryName = this.countryOptions.data.find((s)=>{
                return (s.value == this.selectedCountry);
            });
            const event = new ShowToastEvent({
                "title": "Success",
                "message": 'Outlook rating for ' + countryName.label + ' saved successfully',
                "variant": "success"
            });
            this.currentState = this.countryRatingRecord.Status__c ;
            this.dispatchEvent(event);
       })
       .catch((err)=>{
            this.showWait = false;
            this.handleError(err);
        })
    }

    handleDraft(event){
        this.savecountryRating(true);
    }

    handlePublish(event){
        this.savecountryRating(false);
    }


    //Find related countryRating record and load strucutral weight section
    findcountryRating(){
       this.showWait = true;
       getCountryRating({
            'month' : this.selectedMonth
            , 'year' : this.selectedYear
            , 'librabryId' : this.selectedCountry
       })
       .then((res)=>{
            this.countryRatingRecord = res;
            this.bindStructuralWeight();
            this.calculateWeight();
            this.showWait = false;
            this.currentState = res.Status__c;
            this.lastSaved = res.LastModifiedDate
       })
       .catch((err)=>{
            this.showWait = false;
            this.handleError(err);
        })
    }

    //Set Page from countryRating record 
    bindStructuralWeight(){
        //Overview
        this.overview = this.countryRatingRecord.Overview__c;
        
        //Set Slider values
        this.sliders[0].value = this.countryRatingRecord.Structural_Weight_1__c;
        this.sliders[1].value = this.countryRatingRecord.Structural_Weight_2__c;
        this.sliders[2].value = this.countryRatingRecord.Structural_Weight_3__c;
        this.sliders[3].value = this.countryRatingRecord.Structural_Weight_4__c;
        this.sliders[4].value = this.countryRatingRecord.Structural_Weight_5__c;
        this.sliders[5].value = this.countryRatingRecord.Structural_Weight_6__c;
        this.sliders[6].value = this.countryRatingRecord.Structural_Weight_7__c;
        this.sliders[7].value = this.countryRatingRecord.Structural_Weight_8__c;
        this.sliders[8].value = this.countryRatingRecord.Structural_Weight_9__c;
        this.sliders[9].value = this.countryRatingRecord.Structural_Weight_10__c;

        let _temp = this.sliders;
        this.sliders = new Array();
        this.sliders = _temp;

        //Set countryRating List
        //For Govt Stability
        this.countryRatingList[0].structuralWeight = this.countryRatingRecord.Gov_Stability_Cohesion__c;
        this.countryRatingList[0].outlookShortTerm = this.countryRatingRecord.Gov_Stability_Cohesion_Outlook_6_Months__c;
        this.countryRatingList[0].impactShortTerm = this.countryRatingRecord.Gov_Stability_Cohesion_Impact_6_Months__c; 
        this.countryRatingList[0].outlookLongTerm = this.countryRatingRecord.Gov_Stability_Cohesion_Outlook_24_Months__c; 
        this.countryRatingList[0].impactLongTerm =  this.countryRatingRecord.Gov_Stability_Cohesion_Impact_24_Months__c;

        //For Scoial Stability
        this.countryRatingList[1].structuralWeight = this.countryRatingRecord.Social_Stability__c;
        this.countryRatingList[1].outlookShortTerm = this.countryRatingRecord.Social_Stability_Outlook_6_months__c;
        this.countryRatingList[1].impactShortTerm = this.countryRatingRecord.Social_Stability_Impact_6_Months__c; 
        this.countryRatingList[1].outlookLongTerm = this.countryRatingRecord.Social_Stability_Outlook_24_Months__c; 
        this.countryRatingList[1].impactLongTerm =  this.countryRatingRecord.Social_Stability_Impact_24_Months__c;


        //For Security
        this.countryRatingList[2].structuralWeight = this.countryRatingRecord.Security__c;
        this.countryRatingList[2].outlookShortTerm = this.countryRatingRecord.Security_Outlook_6_months__c;
        this.countryRatingList[2].impactShortTerm = this.countryRatingRecord.Security_Impact_6_Months__c; 
        this.countryRatingList[2].outlookLongTerm = this.countryRatingRecord.Security_Outlook_24_Months__c; 
        this.countryRatingList[2].impactLongTerm =  this.countryRatingRecord.Security_Impact_24_Months__c;

        //For Economic Policy
        this.countryRatingList[3].structuralWeight = this.countryRatingRecord.Economic_Policy_Macro__c;
        this.countryRatingList[3].outlookShortTerm = this.countryRatingRecord.Economic_Policy_Macro_Outlook_6_month__c;
        this.countryRatingList[3].impactShortTerm = this.countryRatingRecord.Economic_Policy_Macro_Impact_6_Months__c; 
        this.countryRatingList[3].outlookLongTerm = this.countryRatingRecord.Economic_Policy_Macro_Outlook_24_month__c; 
        this.countryRatingList[3].impactLongTerm =  this.countryRatingRecord.Economic_Policy_Macro_Impact_24_Months__c;

        //For Investment Policy
        this.countryRatingList[4].structuralWeight = this.countryRatingRecord.Investment_Policy__c;
        this.countryRatingList[4].outlookShortTerm = this.countryRatingRecord.Investment_Policy_Outlook_6_months__c;
        this.countryRatingList[4].impactShortTerm = this.countryRatingRecord.Investment_Policy_Impact_6_months__c; 
        this.countryRatingList[4].outlookLongTerm = this.countryRatingRecord.Investment_Policy_Outlook_24_Months__c; 
        this.countryRatingList[4].impactLongTerm =  this.countryRatingRecord.Investment_Policy_Impact_24_Months__c;

        _temp = this.countryRatingList;
        this.countryRatingList = new Array();
        this.countryRatingList = _temp;
    }

    //To Save Data back to countryRating record
    bindcountryRatingRecord(){
        //Set slider values
        this.countryRatingRecord.Structural_Weight_1__c = this.sliders[0].value;
        this.countryRatingRecord.Structural_Weight_2__c = this.sliders[1].value;
        this.countryRatingRecord.Structural_Weight_3__c = this.sliders[2].value;
        this.countryRatingRecord.Structural_Weight_4__c = this.sliders[3].value;
        this.countryRatingRecord.Structural_Weight_5__c = this.sliders[4].value;
        this.countryRatingRecord.Structural_Weight_6__c = this.sliders[5].value;
        this.countryRatingRecord.Structural_Weight_7__c = this.sliders[6].value;
        this.countryRatingRecord.Structural_Weight_8__c = this.sliders[7].value;
        this.countryRatingRecord.Structural_Weight_9__c = this.sliders[8].value;
        this.countryRatingRecord.Structural_Weight_10__c = this.sliders[9].value;



        //Set countryRating List
        //For Govt Stability
        this.countryRatingRecord.Gov_Stability_Cohesion__c = this.countryRatingList[0].structuralWeight;
        this.countryRatingRecord.Gov_Stability_Cohesion_Outlook_6_Months__c =  this.countryRatingList[0].outlookShortTerm;
        this.countryRatingRecord.Gov_Stability_Cohesion_Impact_6_Months__c = this.countryRatingList[0].impactShortTerm; 
        this.countryRatingRecord.Gov_Stability_Cohesion_Outlook_24_Months__c = this.countryRatingList[0].outlookLongTerm; 
        this.countryRatingRecord.Gov_Stability_Cohesion_Impact_24_Months__c = this.countryRatingList[0].impactLongTerm

        //For Scoial Stability,
        this.countryRatingRecord.Social_Stability__c = this.countryRatingList[1].structuralWeight;
        this.countryRatingRecord.Social_Stability_Outlook_6_months__c = this.countryRatingList[1].outlookShortTerm;
        this.countryRatingRecord.Social_Stability_Impact_6_Months__c = this.countryRatingList[1].impactShortTerm;
        this.countryRatingRecord.Social_Stability_Outlook_24_Months__c = this.countryRatingList[1].outlookLongTerm;
        this.countryRatingRecord.Social_Stability_Impact_24_Months__c = this.countryRatingList[1].impactLongTerm;


        //For Security
        this.countryRatingRecord.Security__c = this.countryRatingList[2].structuralWeight;
        this.countryRatingRecord.Security_Outlook_6_months__c = this.countryRatingList[2].outlookShortTerm;
        this.countryRatingRecord.Security_Impact_6_Months__c = this.countryRatingList[2].impactShortTerm;
        this.countryRatingRecord.Security_Outlook_24_Months__c = this.countryRatingList[2].outlookLongTerm;
        this.countryRatingRecord.Security_Impact_24_Months__c = this.countryRatingList[2].impactLongTerm;

        //For Economic Policy
        this.countryRatingRecord.Economic_Policy_Macro__c = this.countryRatingList[3].structuralWeight;
        this.countryRatingRecord.Economic_Policy_Macro_Outlook_6_month__c = this.countryRatingList[3].outlookShortTerm;
        this.countryRatingRecord.Economic_Policy_Macro_Impact_6_Months__c = this.countryRatingList[3].impactShortTerm;
        this.countryRatingRecord.Economic_Policy_Macro_Outlook_24_month__c = this.countryRatingList[3].outlookLongTerm;
        this.countryRatingRecord.Economic_Policy_Macro_Impact_24_Months__c = this.countryRatingList[3].impactLongTerm;

        //For Investment Policy
        this.countryRatingRecord.Investment_Policy__c = this.countryRatingList[0].structuralWeight;
        this.countryRatingRecord.Investment_Policy_Outlook_6_months__c = this.countryRatingList[4].outlookShortTerm;
        this.countryRatingRecord.Investment_Policy_Impact_6_months__c = this.countryRatingList[4].impactShortTerm;
        this.countryRatingRecord.Investment_Policy_Outlook_24_Months__c = this.countryRatingList[4].outlookLongTerm;
        this.countryRatingRecord.Investment_Policy_Impact_24_Months__c = this.countryRatingList[4].impactLongTerm;

        //Raw Score & countryRating
        this.countryRatingRecord.Political_countryRating_6_Months__c = this.shortTermRating;
        this.countryRatingRecord.Political_countryRating_24_Months__c = this.longTermRating;
        this.countryRatingRecord.Raw_Score_6_Months__c = this.shortTermRawScore;
        this.countryRatingRecord.Raw_Score_24_Months__c = this.longTermRawScore;
        
    }

    calculateWeight(){
        const rating = new RatingCalculator(this.sliders, this.countryRatingList);
        rating.calc();
        let index = 0;
        this.countryRatingList.forEach(countryRating=>{
            countryRating.structuralWeight = Number(rating.eigenVectors[index]);
            index++;
        });
        

        let _temp = this.countryRatingList;
        this.countryRatingList = new Array();
        this.countryRatingList = _temp;

        this.shortTermRawScore = Number(rating.weightedSTSum);
        this.longTermRawScore = Number(rating.weightedLTSum);
    }



    handleError(error) {
        this.showWait = false;
         console.dir(error);
         const event = new ShowToastEvent({
            "title": "Error!",
            "message": error.body.message,
            "variant": "error"
         });
         this.dispatchEvent(event);
    }

    countryRatingList = [
        { id : 0,  dimesion: 'Government Stability/Cohesion', structuralWeight : 20.6 , outlookShortTerm: '', impactShortTerm: '', outlookLongTerm: '', impactLongTerm: ''}
        , { id : 1,  dimesion: 'Scoial Stability', structuralWeight : 23.6 , outlookShortTerm: '', impactShortTerm: '', outlookLongTerm: '', impactLongTerm: ''}
        , { id : 2,  dimesion: 'Security', structuralWeight :10.6 , outlookShortTerm: '', impactShortTerm: '', outlookLongTerm: '', impactLongTerm: ''}
        , { id : 3,  dimesion: 'Economic Policy (Macro)', structuralWeight : 20.6 , outlookShortTerm: '', impactShortTerm: '', outlookLongTerm: '', impactLongTerm: ''}
        , { id : 4,  dimesion: 'Investment Policy (Micro)', structuralWeight : 20.6 , outlookShortTerm: '', impactShortTerm: '', outlookLongTerm: '', impactLongTerm: ''}
    ];

    
    sliders = [
        {id:0 , label: 'Social Stability', value: 0,backgroundSize:'0% 100%' , rightLabel: 'Govt Stability/Cohesion'}
        , {id:1 , label: 'Security', value: 0 , rightLabel: 'Govt Stability/Cohesion'}
        , {id:2 , label: 'Economic Policy (Macro)', value: 0 , rightLabel: 'Govt Stability/Cohesion'}
        , {id:3 , label: 'Investment Policy', value: 0 , rightLabel: 'Govt Stability/Cohesion'}
        , {id:4 , label: 'Security', value: 0 , rightLabel: 'Social Stability'}
        , {id:5 , label: 'Economic Policy (Macro)', value: 0 , rightLabel: 'Social Stability'}
        , {id:6 , label: 'Investment Policy', value: 0 , rightLabel: 'Social Stability'}
        , {id:7 , label: 'Economic Policy (Macro)', value: 0 , rightLabel: 'Security'}
        , {id:8 , label: 'Investment Policy', value: 0 , rightLabel: 'Security'}
        , {id:9 , label: 'Investment Policy', value: 0 , rightLabel: 'Economic Policy (Macro)'}
    ]; 

    
}