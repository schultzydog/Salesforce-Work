import { api, LightningElement } from 'lwc';

//import imperative apex methods...
import searchApex from '@salesforce/apex/egCustomLookup_Ctlr.searchApex';

export default class EgCustomLookup extends LightningElement {

    //Public
    @api type; //sObject Type
    @api value; //record.Id
    @api selection; //record.Name
    @api label; //text of label
    @api additionalStyle; //style of form-element
    @api iconName = 'standard:account';
    @api placeholder = 'Search...';
    @api disabled = false;

    @api filterValue; //for narrowing down query
    @api filterField; //for narrowing down query

    //Private
    isWorking = false;
    timeout = null;
    queryString = null;
    results = null;
    showList = false;
    error = null;

    //UI Getters
    get comboboxContainerClass(){
        return 'slds-combobox_container' + ((this.value) ? ' slds-has-selection' : '');   
    }
    get comboboxClass(){
        return 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click' + ((this.showList) ? ' slds-is-open' : '');   
    }

    connectedCallback() {
        //lightning-input disabled cursor hack - CSS Styling Hooks not available for cursor for inputs...
        const inputAligncenter = document.createElement('style');
        inputAligncenter .innerText = `input[disabled], input[disable]:hover { cursor: default !important; }`;
        document.body.appendChild(inputAligncenter);
    }

    renderedCallback(){
        //hack to allow scrollbar select, don't know why this is necessary in Custom Tab?
        this.template.querySelector(".slds-dropdown_fluid").addEventListener("mousedown", (e) => {
            e.stopPropagation();
            e.preventDefault();
        } , false);
    }

    inputOnFocus(){
        //show list with some default items (empty search)...
        this.queryString = null;
        this.results = null;
        this.showList = true;
        this.search();
    }
    inputOnBlur(event){
        //clear search query and hide list...
        this.queryString = null;
        this.showList = false;
    }
    handleSearch(event) {
        //wait until pause in typing and search query...
        this.queryString = event.currentTarget.value;
        
        if (this.queryString != null && this.queryString.length <= 1) return;

        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            console.log('Ready to search()...', this.queryString);            
            this.search(this.queryString);
        }, 300);
    }
    stop(event){
        console.log('stop prop')
        event.stopPropagation();
    }
    search(queryString) {
        //perform search on server...
        this.isWorking = true;
        this.error = null;

        console.log("filter field: " + this.filterField);
        console.log("filter value: " + this.filterValue);

        searchApex({ 
            type: this.type,
            queryString: queryString,
            filterValue: this.filterValue,
            filterField: this.filterField
         })
        .then((items) => {
            if(items && items.length>0){
                this.results = items;
            } else {
                this.results = null;
            }
        })
        .catch((error) => {
            this.error = error;
            this.results = null;
            console.error(this.error);
        })
        .finally(() => {
            this.isWorking = false;
        });

    }

    select(event) {
        //list item has been selected...
        this.value = event.currentTarget.dataset.id;
        this.selection = event.currentTarget.dataset.name;

        console.log('selected: ', this.value, this.selection);

        //reset search and results...
        this.queryString = null;
        this.results = null;
        this.showList = false;

        this.dispatchEvent(new CustomEvent('select',{detail:{value:this.value, selection:this.selection}}));
    }

    remove() {
        //clear selected value...
        this.value = null;
        this.selection = null;

        //reset search and results...
        this.queryString = null;
        this.results = null;
        this.showList = false;

        //redo default drop down results...
        this.search();

        this.dispatchEvent(new CustomEvent('select',{detail:{value:this.value, selection:this.selection}}));
    }

}