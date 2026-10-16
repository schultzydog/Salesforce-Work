import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import ClientPortal from '@salesforce/resourceUrl/ClientPortal';

import getPageDataApex from "@salesforce/apex/ClientPortal_RequestForm_Ctlr.getPageDataApex";
import saveLeadApex from "@salesforce/apex/ClientPortal_RequestForm_Ctlr.saveLeadApex";

export default class ClientPortal_RequestForm extends LightningElement {

    //Private - Tracked
    @track library = {};
    @track showForm = false;
    @track isWorking = true;
    @track isLoading = true;
    @track formMessage;
    @track errorMessage;

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
            getPageDataApex({libraryId: this.urlStateParameters.lib})
            .then((library) => {
                //Success
                this.library = library;
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
        fields.LeadSource = 'Subscription Request Form'; //changed from Company Referral to Subscription Request From, per Adam, 12/1/2022 bry
        fields.Description = 'Subscription request for ' + this.library.Name + ' library';

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