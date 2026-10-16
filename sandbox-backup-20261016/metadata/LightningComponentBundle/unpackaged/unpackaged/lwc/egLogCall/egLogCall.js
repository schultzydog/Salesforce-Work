import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import EVENT_TYPE_FIELD from '@salesforce/schema/Event.Type';
import initalize from '@salesforce/apex/egLogCallController.initalize';
import saveEvent from '@salesforce/apex/egLogCallController.saveEvent';



export default class EgLogCall extends NavigationMixin(LightningElement) {
    showSpinner = false;
    @api recordId;
    @api objectApiName;
    eventTypeOption = [];
    eventType = 'Meeting';
    durationInMinutes = '60';
    ownerId;
    ownerName;
    defaultToday;
    oppId;
    oppName;
    oppLineItemId;
    oppLineItemName;
    existingEvent;
    durationOptions = [ 
        { label: '30 minutes', value: '30'},
        { label: '60 minutes', value: '60' },
        { label: '90 minutes', value: '90' },
        { label: '120 minutes', value: '120' }];



    
    originatingAccountId;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            if(currentPageReference.state.c__recordId){
                this.recordId = currentPageReference.state.c__recordId;
                this.init();
            }
        }
    }

    get hasExistingEvent(){
        return this.existingEvent != null;
    }
    ///apex/taskassignmentpage?nooverride=1&what_id={!Account.Id}
    
    get noProject(){
        return this.oppId == null;
    }

    accountColumns =[
        { label: 'Name', fieldName: 'Name', hideDefaultActions:true },
        { label: 'Type', fieldName: 'Type', hideDefaultActions:true },
       // { label: 'Business Line', fieldName: 'Business_Line__c' , hideDefaultActions:true},
        //{ label: 'City', fieldName: 'BillingCity' , hideDefaultActions:true},
    ];

    userColumns =[
        { label: 'Name', fieldName: 'Name' , hideDefaultActions:true},
        { label: 'Phone', fieldName: 'Phone', type: 'phone' , hideDefaultActions:true},
       // { label: 'Fax', fieldName: 'Fax', type: 'phone' , hideDefaultActions:true},
      //  { label: 'City', fieldName: 'City' , hideDefaultActions:true},
    ];

    contactColumns =[
        { label: 'Name', fieldName: 'Name' , hideDefaultActions:true},
        { label: 'Account', fieldName: 'AccountName__c' , hideDefaultActions:true},
       // { label: 'Title', fieldName: 'Title' , hideDefaultActions:true},
       // { label: 'Status', fieldName: 'Status__c' , hideDefaultActions:true},
    ];
    
    eventId;

   

   @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: EVENT_TYPE_FIELD })
    wiredEventType({ error, data }) {
        if (data) {
            let _data = [];

            data.values.forEach(picklist => {
                if(picklist.label != 'EG Conference Call' && picklist.label != 'Roundtable'){
                    _data.push(picklist);
                }
            });
            this.eventTypeOption = this.eventTypeOption.concat(_data);
            //this.eventTypeOption = data.values;
            //this.eventType = this.eventTypeOption.value;
        } else if (error) {
           
        }
    }


    init(){
        this.showSpinner = true;
        initalize({
            recordId:this.recordId
        })
        .then((res)=>{
            this.showSpinner = false;
            console.dir(res);
            this.originatingAccountId = res.originatingAccountId;
            this.defaultToday = res.defaultToday;
            this.ownerId = res.eventOwner.Id;
            this.ownerName= res.eventOwner.Name;
            if(res.existingEvent){
                this.existingEvent = res.existingEvent;
                this.eventType = this.existingEvent.Type;
                this.template.querySelector('lightning-input[data-name="subject"]').value = this.existingEvent.Subject;
                this.template.querySelector('lightning-input[data-name="start"]').value = this.existingEvent.StartDateTime;
                this.template.querySelector('lightning-textarea[data-name="background"]').value = this.existingEvent.Description;
                this.durationInMinutes = this.existingEvent.DurationInMinutes.toString();
            }

            if(res.opportunityLineItem){
                this.oppLineItemId = res.opportunityLineItem.Id;
                this.oppLineItemName = res.opportunityLineItem.Name;
            }

            if(res.opportunity){
                this.oppId = res.opportunity.Id;
                this.oppName = res.opportunity.Name;
            }

            //Set Selected Users
            this.template.querySelector('c-multi-select-lookup[data-name="users"]').setSelected(res.selectedUsers);

            //Set Selected Accounts
            this.template.querySelector('c-multi-select-lookup[data-name="account"]').setSelected(res.selectedAccounts);


            //Set Selected Contacts
            this.template.querySelector('c-multi-select-lookup[data-name="contact"]').setSelected(res.selectedContacts);
            this.setSelectedAccountIds(res.selectedAccounts);
            


        })
        .catch(e=>{
            this.showSpinner = false;
            console.dir(e);
        })

    }


    setSelectedAccountIds(selectedAccounts){
        let _selectAccountIds = selectedAccounts.map(item=>{return item.record.Id;});
        this.template.querySelector('c-multi-select-lookup[data-name="contact"]').setParentIds(_selectAccountIds);
        

    }

    handleLookupSelection(event){
        //get values from custom dispatch event "select"...
        let type = event.target.type;
        let value = event.target.value;
        let selection = event.target.selection;


        if(type=='Opportunity'){
            //Project has changed...
            console.log('Handle Project change...')
            if(this.oppId != value){ //If Project is changed, clear Project Task
                this.oppLineItemId = null;
                this.oppLineItemName = null;
            }
            if(value){
                //Project is selected...
                this.oppId = value;
                this.oppName = selection;
            } else {
                //No Project selected...
                this.oppId = null;
                this.oppName = null;  
            }
        } else if(type=='OpportunityLineItem'){
            //Task has changed...
            if(value){
                //Task is selected...
                this.oppLineItemId = value;
                this.oppLineItemName = selection;
            } else {
                //No Task selected...
                this.oppLineItemId = null;
                this.oppLineItemName = null;
            }
        } else if(type=='User'){
            //Task has changed...
            if(value){
                //Task is selected...
                this.ownerId = value;
                this.ownerName = selection;
            } else {
                /*//No Task selected...
                this.ownerId = null;
                this.ownerName = null;
                */
            }
        }
    }

    connectedCallback(){
        this.init();
    }

    

    handleCancel(event){
        this.goToRecord(this.recordId, this.objectApiName);
        

    }

    handleSave(event){

        const allValid = [
            ...this.template.querySelectorAll('lightning-input[data-type="event"]'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
            let subject = this.template.querySelector('lightning-input[data-name="subject"]').value;
            let meetingType = this.template.querySelector('lightning-combobox[data-name="type"]').value;
            let notes = this.template.querySelector('lightning-textarea[data-name="background"]').value;
            let duraion = this.template.querySelector('lightning-combobox[data-name="end"]').value;
            let startDate =   this.template.querySelector('lightning-input[data-name="start"]').value;

            //Get Selected Users
            let _selectedUsers =  this.template.querySelector('c-multi-select-lookup[data-name="users"]').getSelected();
            let users = _selectedUsers.map(item=>{return item.record.Id});
            
            //Set Selected Contacts
            let _selectedContacts =  this.template.querySelector('c-multi-select-lookup[data-name="contact"]').getSelected();
            let contacts = _selectedContacts.map(item=>{return item.record.Id});



            
           
            if(this.oppId){
                this.originatingAccountId = this.oppId;
            }

           let existingEventId;
           if(this.existingEvent){
                existingEventId = this.existingEvent.Id;
           }

           saveEvent({
                'existingEventId' : existingEventId
                , 'subject':subject
                ,'meetingType':meetingType
                ,'startDate': startDate
                ,'duraion': duraion
                ,'notes':notes
                ,'users':users
                ,'contacts': contacts
                ,'originatingAccountId': this.originatingAccountId
                , 'opportunityLineItemId' : this.oppLineItemId
                , 'eventOwnerId' : this.ownerId
            }).then(res=>{
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Call logged successfully',
                    variant: 'success'
                });
                this.dispatchEvent(evt);
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        objectApiName: 'Event',
                        actionName: 'view',
                        recordId : res
                    },
                });
            }).catch(res=>{
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: res,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            })
        } else {
            
        }

    }



    goToRecord(id, objectAPIName){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: objectAPIName,
                actionName: 'view',
                recordId : id
    
            },
        });
    }  


    //Type Ahead Search 
    @track selectedItemsToDisplay = ''; //to display items in comma-delimited way
    @track values = []; //stores the labels in this array
    @track isItemExists = false; //flag to check if message can be displayed

    //captures the retrieve event propagated from lookup component
    selectItemEventHandler(event){
        const name = event.target.dataset.name;
        console.dir(name);
        let args = JSON.parse(JSON.stringify(event.detail.arrItems));
        this.displayItem(args);    
        if(name =='account'){
            this.setSelectedAccountIds(event.detail.arrItems);
            
            

        }    
    }

    //captures the remove event propagated from lookup component
    deleteItemEventHandler(event){
        const name = event.target.dataset.name;
        console.dir(name);
        let args = JSON.parse(JSON.stringify(event.detail.arrItems));
        this.displayItem(args);
        if(name =='account'){
            this.setSelectedAccountIds(event.detail.arrItems);

            //remove Account list 
            let _newContactList = [];
            let _existingContacts = this.template.querySelector('c-multi-select-lookup[data-name="contact"]').getSelected();
            _existingContacts.forEach(item=>{
                let _add = false;
                event.detail.arrItems.forEach(account=>{
                    if(item.record.AccountId == account.record.Id){
                        _add = true;
                    }
                });
                if(_add){
                    _newContactList.push(item);
                }
            });

            this.template.querySelector('c-multi-select-lookup[data-name="contact"]').setSelected(_newContactList);
        }
    }

    //displays the items in comma-delimited way
    displayItem(args){
        this.values = []; //initialize first
        args.map(element=>{
            this.values.push(element.label);
        });

        this.isItemExists = (args.length>0);
        this.selectedItemsToDisplay = this.values.join(', ');
        
    }

}