import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getSubscribersApex from "@salesforce/apex/ClientPortal_Subscribers_Ctlr.getSubscribersApex";
import getContactPreferencesApex from "@salesforce/apex/ClientPortal_Subscribers_Ctlr.getContactPreferencesApex";
import saveContactPreferencesApex from "@salesforce/apex/ClientPortal_Subscribers_Ctlr.saveContactPreferencesApex";
import updateContactApex from "@salesforce/apex/ClientPortal_Subscribers_Ctlr.updateContactApex";

import Contact_FirstName from '@salesforce/schema/Contact.FirstName';
import Contact_LastName from '@salesforce/schema/Contact.LastName';
import Contact_Title from '@salesforce/schema/Contact.Title';
import Contact_Email from '@salesforce/schema/Contact.Email';
import Contact_MailingCity from '@salesforce/schema/Contact.MailingCity';
import Contact_MailingState from '@salesforce/schema/Contact.MailingState';
import Contact_MailingCountry from '@salesforce/schema/Contact.MailingCountry';
import Contact_Phone from '@salesforce/schema/Contact.Phone';
import Contact_Status__c from '@salesforce/schema/Contact.Status__c';

import User_Id from '@salesforce/user/Id';

import customPermission_clientPortalSelfServiceAdministration from '@salesforce/customPermission/Client_Portal_Self_Service_Administration';

export default class ClientPortal_Subscribers extends LightningElement {

    //Private - Tracked
    @track isWorking = true;
    @track subscribers = [];
    @track selectedSubscriber = null;
    @track showContactPreferencesModalFor;
    @track showToggleStatusConfirmFor;
    @track errorMessage = null;
    @track masterPreferences;
    @track masterPreferencesSrc;
    @track searchTerm = null;
    @track pageNumber = 1;
    @track pageSize = 20;
    @track hasPrevious = false;
    @track hasNext = false;
    
    FirstName = Contact_FirstName;
    LastName = Contact_LastName;
    Title = Contact_Title;
    Email = Contact_Email;
    MailingCity = Contact_MailingCity;
    MailingState = Contact_MailingState;
    MailingCountry = Contact_MailingCountry;
    Phone = Contact_Phone;
    Status__c = Contact_Status__c;
    
    //Private
    hasRendered = false; //Only initialize of first render
    
    //UI Getters
    get contactModalHeader() {
        return (this.selectedSubscriber && this.selectedSubscriber.Id) ? 'Edit Contact Details' : 'Add Subscriber';
    }
    get previousDisabled() {
        return (!this.hasPrevious);
    }
    get nextDisabled() {
        return (!this.hasNext);
    }
    get hasSubscribers() {
        return (this.subscribers && this.subscribers.length>0);
    }
    get isSelfServiceAdministrator() {
        return customPermission_clientPortalSelfServiceAdministration;
    }

    //Rendered Callback
    renderedCallback() {
        if (!this.hasRendered) {
            this.hasRendered = true;
            this.initComponent();
        }
    } //end renderedCallback
    
    //Initialize Component
    initComponent = async () => { 
        this.isWorking = true;
    
        if(this.isSelfServiceAdministrator){
            this.subscribers = await getSubscribersApex({searchTerm: this.searchTerm, pageNumber: this.pageNumber, pageSize: this.pageSize});

            if(this.subscribers && this.subscribers.length>0){
                if(this.subscribers.length==this.pageSize+1){
                    this.subscribers.pop();
                    this.hasNext = true;
                } else {
                    this.hasNext = false;
                }

                for(let subscriber of this.subscribers){
                    if(!subscriber.Status__c) subscriber.Status__c='Disabled'; //empty status should show as Disabled
                    subscriber.isEnabled = subscriber.Status__c=='Enabled';
                    subscriber.toggleStatusLabel = (subscriber.isEnabled) ? 'Disable Contact' : 'Enable Contact';
                    subscriber.toggleStatusIconName = (subscriber.isEnabled) ? 'utility:close' : 'utility:check';                
                }
            }

            this.hasPrevious = (this.pageNumber>1);
        }
        this.isWorking = false;
    }

    prepMasterPreferences(masterPreferences){
        if(masterPreferences && masterPreferences.length>0){
            for(let masterPreference of masterPreferences){
                
                
                let indTotal = 0;
                let indAvailable = 0;
                let indSelected = 0;
                let dailyTotal = 0;
                let dailyAvailable = 0;
                let dailySelected = 0;

                if(masterPreference.libs && masterPreference.libs.length>0){
                    for(let lib of masterPreference.libs){
                        lib.isNa = lib.state=='N/A';
                        if(lib.isNa || lib.lib.Exclusive_List__c){
                            lib.showRow = false;
                        } else {
                            lib.showRow = true;
                        }

                        indTotal++;
                        dailyTotal++;
                        if(!lib.isNa && !lib.lib.Exclusive_List__c){
                            indAvailable++;
                            dailyAvailable++;
                            if(lib.ind) indSelected++;
                            if(lib.daily) dailySelected++;
                        }
                    }

                    masterPreference.isIndividualStateNone = false;
                    masterPreference.isIndividualStateAll = false;
                    masterPreference.isIndividualStateSome = false;
                    if(indAvailable==0){
                        masterPreference.indState = 'N/A';
                        masterPreference.isIndividualStateNone = true;
                    } else if(indSelected==0){
                        masterPreference.indState = indSelected + ' of ' + indAvailable;
                        masterPreference.isIndividualStateNone = true;
                    } else if(indSelected==indAvailable){
                        masterPreference.indState = indSelected + ' of ' + indAvailable;
                        masterPreference.isIndividualStateAll = true;
                    } else if(indSelected<indAvailable){
                        masterPreference.indState = indSelected + ' of ' + indAvailable;
                        masterPreference.isIndividualStateSome = true;
                    }

                    masterPreference.isDailyStateNone = false;
                    masterPreference.isDailyStateAll = false;
                    masterPreference.isDailyStateSome = false;
                    if(dailyAvailable==0){
                        masterPreference.dailyState = 'N/A';
                        masterPreference.isDailyStateNone = true;
                    } else if(dailySelected==0){
                        masterPreference.dailyState = dailySelected + ' of ' + dailyAvailable;
                        masterPreference.isDailyStateNone = true;
                    } else if(dailySelected==indAvailable){
                        masterPreference.dailyState = dailySelected + ' of ' + dailyAvailable;
                        masterPreference.isDailyStateAll = true;
                    } else if(dailySelected<indAvailable){
                        masterPreference.dailyState = dailySelected + ' of ' + dailyAvailable;
                        masterPreference.isDailyStateSome = true;
                    }
                }
            }    
        }

        return masterPreferences;
    }

    bind(event){
        let i = event.currentTarget.dataset.i;
        let j = event.currentTarget.dataset.j;
        let name = event.target.name;
        let checked = event.target.checked;

        this.masterPreferences[i].libs[j][name] = checked;

        this.masterPreferences = this.prepMasterPreferences(this.masterPreferences);
    }

    search = async (event) => { 
        this.pageNumber = 1;
        this.searchTerm = event.target.value;
        this.initComponent();
    }

    previous = async (event) => { 
        this.pageNumber--;
        this.initComponent();
    }
    next = async (event) => { 
        this.pageNumber++;
        this.initComponent();
    }

    clearErrorMessage(event){
        this.errorMessage = null;
     }
 
    editContact(event){
        this.isWorking = true;
        this.errorMessage = null;

        let contactId = event.currentTarget.dataset.contactId;
        
        let contact = {Id: contactId};
        if(!contactId) contact.Status__c = 'Enabled';

        this.selectedSubscriber = contact;
    }
    
    cancel(event){
        this.selectedSubscriber = null;
        this.errorMessage = null;
    }
    
    save(event){
        this.isWorking = true;
        this.errorMessage = null;
        this.template.querySelector('.hidden-in-form').click();
        this.isWorking = false;
    }

    handleLoad(event){
        this.isWorking = false;
    }
    
    handleSubmit(event){
        event.preventDefault();
        this.isWorking = true;

        const fields = event.detail.fields;
        fields.AccountId = '00130000017hIT6AAM'; //FIX THIS - Prod
        //fields.AccountId = '00174000008MwM8AAK'; //FIX THIS - Dev
        fields.Worldflow_Email_Access__c = true;
        if(!this.selectedSubscriber.Id) fields.Status__c = 'Enabled';

        // You need to submit the form after modifications
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event){
        this.selectedSubscriber = null;
        this.initComponent();
        this.isWorking = false;
    }

    handleError(event){
        //this.errorMessage = 'Unable to Save (202203-01)'; //As of Summer 22 in PROD, error messages are now handle with Salesforce bug fix, extra message no longer needed
        this.isWorking = false;
    }

    showContactPreferences = async (event) => { 
        this.isWorking = true;

        let contactId = event.currentTarget.dataset.contactId;
        let contactKey = event.currentTarget.dataset.contactKey;
        let contactName = event.currentTarget.dataset.contactName;
        
        this.masterPreferencesSrc = 'https://portal-eurasiagroup.cs209.force.com/ContactPreferencesPage?key=' + contactKey + '&prdt=eg';

        this.showContactPreferencesModalFor = {Id: contactId, Name: contactName};

        this.masterPreferences = this.prepMasterPreferences(await getContactPreferencesApex({contactId: contactId}))
        
        this.isWorking = false;
    }

    cancelContactPreferences(){
        this.showContactPreferencesModalFor = null;
    }

    saveContactPreferences = async (event) => {
        this.isWorking = true;

        let contactId = this.showContactPreferencesModalFor.Id;

        let libs = [];
        for(let masterPreference of this.masterPreferences){
            if(masterPreference.libs && masterPreference.libs.length>0){
                for(let lib of masterPreference.libs){
                    if(lib.No_Summary_Emails_Option__c) lib.daily = lib.orig_daily;
                    libs.push(lib);
                }
            }
        }

        await saveContactPreferencesApex({contactId: contactId, libs: JSON.stringify(libs)});

        this.initComponent();

        this.showContactPreferencesModalFor = null;

        this.isWorking = false;
    }

    handleSubscriberAction = async (event) => { 
        let selectedAction = event.detail.value;
        
        if(selectedAction=='editContact'){
            this.editContact(event);
        } else if(selectedAction=='manageSubscription'){
            this.showContactPreferences(event);
        } else if(selectedAction=='toggleStatus'){
            this.showToggleStatus(event);
        }

    }

    showToggleStatus(event){
        let i = event.currentTarget.dataset.i;
        let contact = this.subscribers[i];

        this.showToggleStatusConfirmFor = {
            i: i,
            Id: contact.Id,
            Name: contact.Name,
            Status__c: (contact.Status__c=='Enabled') ? 'Disabled' : 'Enabled'
        };
    }

    confirmToggleStatus = async (event) => {
        this.isWorking = true;

        let updatedContact = await updateContactApex({contact: this.showToggleStatusConfirmFor})
        
        this.showToggleStatusConfirmFor = null;
        this.initComponent();
        this.isWorking = false;
    }

    cancelToggleStatus = async (event) => {
        this.showToggleStatusConfirmFor = null;
    }

    toggleCategory(event){
        let i = event.currentTarget.dataset.i;
        let category = event.currentTarget.dataset.category;
        
        for(let lib of this.masterPreferences[i].libs){
            let checked = false;
            if(category=='ind'){
                checked = (this.masterPreferences[i].isIndividualStateNone || this.masterPreferences[i].isIndividualStateSome);
            } else if(category=='daily'){
                checked = (this.masterPreferences[i].isDailyStateNone || this.masterPreferences[i].isDailyStateSome);
            }
            if(lib.showRow) lib[category] = checked;
        }

        this.masterPreferences = this.prepMasterPreferences(this.masterPreferences);
    }

}