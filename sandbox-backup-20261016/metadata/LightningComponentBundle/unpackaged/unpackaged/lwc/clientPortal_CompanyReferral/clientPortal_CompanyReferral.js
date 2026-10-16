import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ClientPortal from '@salesforce/resourceUrl/ClientPortal';

import getCompanyFromReferralKeyApex from "@salesforce/apex/ClientPortal_CompanyReferral_Ctlr.getCompanyFromReferralKeyApex";
import saveLeadApex from "@salesforce/apex/ClientPortal_CompanyReferral_Ctlr.saveLeadApex";

export default class ClientPortal_CompanyReferral extends LightningElement {

    //Private - Tracked
    @track company = {};
    @track showForm = false;
    @track isWorking = true;
    @track isLoading = true;
    @track formMessage;
    @track errorMessage;

    //Private
    hasRendered = false; //Only initialize of first render

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if(currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            this.initComponent();
        }
    }

    //UI Getters
    get logoUrl() {
        return ClientPortal + '/img/EG Logo_Horizontal.png'
    }


    //Initialize Component
    initComponent = async () => { 
        this.isWorking = true;

        try{
            //this.company = await getCompanyFromReferralKeyApex({contactKey: this.urlStateParameters.source});
            getCompanyFromReferralKeyApex({recordLocator: this.urlStateParameters.source})
            .then((company) => {
                //Success
                this.company = company;
                this.showForm = true;
                //this.isWorking = false;
            })
            .catch((e) => {
                //Error
                this.showForm = false;
                this.isWorking = false;
                this.formMessage = e.body.message;            
            });
        } catch(e){
            //Error for await
            this.showForm = false;
            this.isWorking = false;
            this.formMessage = e.body.message;            
        }

    }

    handleLoad(){
        this.isWorking = false;
    }

    handleSubmit = async (event) => { 
        event.preventDefault();
        this.isWorking = true;

        const fields = event.detail.fields;
        //fields.LeadSource = 'Company Referral';
        fields.LeadSource = 'Company Sign Up Form'; //changed from Company Referral to Company Sign Up Form, per Adam, 12/1/2022 bry
        fields.OwnerId = this.company.OwnerId;
        fields.Company = this.company.Name;
        fields.Company_Referral_Account_Id__c = this.company.Id;

        // You need to submit the form after modifications
        //this.template.querySelector('lightning-record-edit-form').submit(fields);

        //Save Lead using imperative apex in order to get and control error message
        try{
            //let lead = await saveLeadApex({lead: fields});
            saveLeadApex({lead: fields})
            .then((lead) => {
                //Success
                this.formMessage = 'Thank you. Your request has been submitted.'
                this.showForm = false;
                this.isWorking = false;
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