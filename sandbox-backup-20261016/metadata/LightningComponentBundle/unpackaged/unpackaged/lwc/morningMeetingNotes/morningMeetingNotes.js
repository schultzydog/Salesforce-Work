import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveNote from "@salesforce/apex/MorningMeetingNotesCtrl.saveNote";
import Morning_Meeting_instructions from '@salesforce/label/c.Morning_Meeting_instructions';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import Morning_Meeting_Note_Object from "@salesforce/schema/Morning_Meeting_Note__c";

export default class MorningMeetingNotes extends LightningElement {

    //Private...
    leadAuthorOptions;
    distributionOptions;
    contributorOptions;
    callChangeOrNewCallOptions;

    selectedLeadAuthor;
    selectedDistributions;
    selectedContributors;
    selectedCallChangeOrNewCall;

    @track showForm = true;
    @track isWorking = true;
    @track errorMessage;
    @track formMessage;
    @track showTitlesAndOddsForNewScenarios = false;

    //Wire adapters...
    @wire(getPicklistValuesByRecordType, {
        objectApiName: Morning_Meeting_Note_Object,
        recordTypeId: "012000000000000AAA",
    })
    wiredPicklistValues({error,data}){
        if(data){
            this.leadAuthorOptions = data.picklistFieldValues.egLead_Author__c.values;
            this.distributionOptions = data.picklistFieldValues.Distribution_Lists__c.values;
            this.contributorOptions = data.picklistFieldValues.egContributors__c.values;
            this.callChangeOrNewCallOptions = data.picklistFieldValues.Call_change_or_new_call__c.values;            
            this.isWorking = false;
        }else if(error){
            this.isWorking = true;
        }
    }

    //UI Getters...
    get hasOptionLoaded(){
        return (this.leadAuthorOptions && this.distributionOptions && this.contributorOptions && this.callChangeOrNewCallOptions);
    }
    
    // Expose the labels to use in the template.
    label = {
        Morning_Meeting_instructions
    };

    handleOptionChange(event) {
        switch(event.target.dataset.id){
            case 'leadAuthor':
                this.selectedLeadAuthor = event.detail.payload.value; //singular
                break;
            case 'contributor':
                this.selectedContributors = event.detail.payload.values; //plural
                break;
            case 'distribution':
                this.selectedDistributions = event.detail.payload.values; //plural
                break;
            case 'callChangeOrNewCall': //20250114 - added per Adam
                this.selectedCallChangeOrNewCall = event.detail.payload.value; //singular                
                if(this.selectedCallChangeOrNewCall==='Yes'){
                    this.showTitlesAndOddsForNewScenarios = true;
                } else {
                    this.showTitlesAndOddsForNewScenarios = false;
                }
                break;
        }
    }

    handleSubmit = async (event) => { 
        event.preventDefault();
        this.isWorking = true;
        try{
            let fields = event.detail.fields;
            if(this.selectedLeadAuthor){
                fields.egLead_Author__c  = this.selectedLeadAuthor;
            }
            if(this.selectedContributors){
                fields.egContributors__c  = this.selectedContributors.join(';');
            }
            if(this.selectedDistributions){
                fields.Distribution_Lists__c  = this.selectedDistributions.join(';');
            }
            if(this.selectedCallChangeOrNewCall){
                fields.Call_change_or_new_call__c  = this.selectedCallChangeOrNewCall;
            }
            saveNote({note: fields})
            .then((res) => {
                //Success
                if(res.isSuccess){
                    this.formMessage = 'Note successfully submitted.'
                    this.showForm = false;
                    this.isWorking = false;
                }else{
                    this.errorMessage = res.errorMessage;          
                    this.showForm = true;
                    this.isWorking = false;
                }
            })
            .catch((e) => {
                //Error
                this.errorMessage = e.body.message;            
                this.showForm = true;
                this.isWorking = false;
            });
        } catch(e){
            //Error for await
            this.errorMessage = e.body.message;            
            this.showForm = true;
            this.isWorking = false;
        }
    }

    clearErrorMessage(){
        this.errorMessage = null;
    }
}