/**
 * @last modified on  : 05/18/2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
import { LightningElement, api, wire, track } from 'lwc';
import getObjectInfo from '@salesforce/apex/egRelatedListController.getObjectInfo';
import queryRecords from '@salesforce/apex/egRelatedListController.queryRecords';;
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';

export default class egRelatedList extends NavigationMixin(LightningElement) {
    @api fields;//Fields to Query and Show
    @api recordId;//current record Id
    @api sortQuery;//Order By
    @api relatedObject;// Object to Query
    @api referenceFieldAPI;//reference field API Name 
    @api filterQuery;// Where Clause
    @api iconName;//Heder Icon Name
    @api headerStyle;//Header Style
    @api title;//Header Title
    

    objectDetails;
    @track data = new Array();

    totalRows = 0;
    
    showComponent = true;
    @track showSpinner = false;

    @wire(CurrentPageReference) pageRef;
   
    connectedCallback() {
        this.getDataTableConfiguration();
        this.loadData();
    }


    loadData(){
        var _this = this;
        if(this.recordId){
            this.data = new Array();
            this.totalRows = 0;
            queryRecords({
                    ObjectName: this.relatedObject,
                    fields: this.fields,
                    filterQuery : this.filterQuery,
                    parentField: this.referenceFieldAPI,
                    parentId : this.recordId,
                    sortQuery : this.sortQuery
                })
                .then((result)=>{this.callbackLoadData(result)})
                .catch((error)=>{this.showSpinner = false;});
            
        }else{
            this.data = new Array();
            this.totalRows = 0;
            this.showSpinner = false;
        }
    }


    callbackLoadData(result){
        result.data.forEach(row =>{
            row.recordId = '/'+ row.Id;
            for (const col in row) {
                const curCol = row[col];
                if (typeof curCol === 'object') {
                  const newVal = curCol.Id ? ('/' + curCol.Id) : null;
                  this.flattenStructure(row, col + '_', curCol);
                  if (newVal === null) {
                    delete row[col];
                  } else {
                    row[col] = newVal;
                  }
                }
              }
        });
        this.data = result.data;
        this.totalRows = result.data.size;
        this.showSpinner = false;
    }

    flattenStructure(topObject, prefix, toBeFlattened) {
      for (const prop in toBeFlattened) {
        const curVal = toBeFlattened[prop];
        if (typeof curVal === 'object') {
          flattenStructure(topObject, prefix + prop + '_', curVal);
        } else {
          topObject[prefix + prop] = curVal;
        }
      }
    }

    getDataTableConfiguration(){
        this.showSpinner = true;
        getObjectInfo({
            objectName: this.relatedObject
            , fieldNames: this.fields
        })
        .then(result=>{
            this.objectDetails = result;
            console.dir(result);
            this.showSpinner = false;
        })
        .catch(error=>{
            this.showSpinner = false;
        });
    }
}