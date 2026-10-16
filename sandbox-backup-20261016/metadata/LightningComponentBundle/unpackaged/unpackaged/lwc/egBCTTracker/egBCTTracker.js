import { LightningElement, wire } from 'lwc';

import queryRecords from '@salesforce/apex/egRelatedListController.queryRecords';
import bctYear from "@salesforce/label/c.BCT_Year";

export default class EgBCTTracker extends LightningElement {
    showSpinner = true;

    data = {
        English: [],
        Portuguese: []
    };

    //defaults...
    selectedTable ='Main legislative proposals in congress';
    selectedLanugage ='English';
    sortBy = 'sector'; //also change sortBy query parts in code further below
    sortDirection = 'asc'; //also change sortBy query parts in code further below

    //options...
    languageOptions = [
        { label: 'English', value: 'English' },
        { label: 'Portuguese', value: 'Portuguese' }
    ];
    get tableOptions(){
        if(this.selectedLanugage=='Portuguese'){
            return [
                { label: 'Principais projetos no Congresso', value: 'Main legislative proposals in congress' },
                { label: 'Medidas provisórias em tramitação no Congresso', value: 'Provisional measures under congressional analysis' }
            ];
        } else {
            return [
                { label: 'Main legislative proposals in congress', value: 'Main legislative proposals in congress' },
                { label: 'Provisional measures under congressional analysis', value: 'Provisional measures under congressional analysis' }
            ];
        }
    } 

    //UI Getters
    get rows(){
        return this.data[this.selectedLanugage];
    }    
    get labelTitle(){
        if(this.selectedTable=='Provisional measures under congressional analysis'){
            return (this.selectedLanugage=='Portuguese') ? 'Medidas provisórias em tramitação no Congresso' : 'Provisional measures under congressional analysis';
        } else {
            return (this.selectedLanugage=='Portuguese') ? 'Principais projetos no Congresso' : 'Main legislative proposals in congress';
        }
    }
    get labelSector(){
        return (this.selectedLanugage=='Portuguese') ? 'Setor' : 'Sector';
    }
    get labelProposal(){
        return (this.selectedLanugage=='Portuguese') ? 'Proposta' : 'Proposal';
    }
    get labelType(){
        return (this.selectedLanugage=='Portuguese') ? 'Tipo' : 'Type';
    }
    get labelNumber(){
        return (this.selectedLanugage=='Portuguese') ? 'Número' : 'Number';
    }
    get labelSummary(){
        return (this.selectedLanugage=='Portuguese') ? 'Resumo' : 'Summary';
    }
    get labelStatus(){
        return (this.selectedLanugage=='Portuguese') ? 'Status' : 'Status';
    }
    get labelLikelihood(){
        return (this.selectedLanugage=='Portuguese') ? 'Probabilidade de aprovação em HIDDEN' : 'Likelihood of approval in HIDDEN';
    }
    get labelLikelihoodThisYear(){
        return (this.selectedLanugage=='Portuguese') ? ('Probabilidade de aprovação em ' + bctYear)  : ('Likelihood of approval in ' + bctYear);
    }
    get labelLastModified(){
        return (this.selectedLanugage=='Portuguese') ? 'Atualizada' : 'Updated';
    }
    get labelExpiration(){
        return (this.selectedLanugage=='Portuguese') ? 'Expiração' : 'Expiration';
    }
    get labelNoRows(){
        return (this.selectedLanugage=='Portuguese') ? 'Não há registros a serem exibidos' : 'No records to display';
    }
    get sortIconSector(){        
        if(this.sortBy=='sector'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get sortIconProposal(){        
        if(this.sortBy=='proposal'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get sortIconType(){        
        if(this.sortBy=='type'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get sortIconNumber(){        
        if(this.sortBy=='number'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get sortIconSummary(){        
        if(this.sortBy=='summary'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get sortIconStatus(){        
        if(this.sortBy=='status'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get sortIconLikelihood(){        
        if(this.sortBy=='likelihood'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get sortIconLikelihoodThisYear(){        
        if(this.sortBy=='likelihoodThisYear'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get sortIconLastModified(){        
        if(this.sortBy=='lastModified'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get sortIconExpiration(){        
        if(this.sortBy=='expiration'){
            return (this.sortDirection=='asc') ? 'utility:arrowup' : 'utility:arrowdown';
        } else {
            return null;
        }
    }
    get showTable1(){
        return (this.selectedTable=='Main legislative proposals in congress');
    }
    get showTable2(){
        return (this.selectedTable=='Provisional measures under congressional analysis');
    }
    get hasRows(){
        return this.showSpinner || (this.rows && Array.isArray(this.rows) && this.rows.length>0);
    }

    connectedCallback() {
        this.loadData();
    }

    handleTableChange(event){
        this.selectedTable = event.detail.value;
        this.loadData();
    }

    handleLanguageChange(event){
        this.selectedLanugage = event.detail.value;
    }

    async loadData(){
        this.showSpinner = true;

        //Reset data object by language...
        this.data.English = [];
        this.data.Portuguese = [];

        //Reset sort selectors...
        this.sortBy = (this.selectedTable=='Provisional measures under congressional analysis') ? 'number' : 'sector'; //also change sortBy query parts in code further below
        this.sortDirection = (this.selectedTable=='Provisional measures under congressional analysis') ? 'asc' : 'asc'; //also change sortBy query parts in code further below
    
        //Get records using generic egRelatedListController...
        const objectName = ' BCT__c ';
        const fields = ' Table__c, Sector__c, Sector_Portuguese__c, Summary__c, Proposal__c, Proposal_Portuguese__c, Type__c, Number__c, Number_Text__c, Likelihood__c, Likelihood_this_year__c, Status__c, Summary_Portuguese__c, Status_Portuguese__c, Expiration_Date__c, LastModifiedDate ';
        const filterQuery = ' Publish__c = TRUE AND Table__c = \'' + this.selectedTable + '\' ';
        const sortQuery = (this.selectedTable=='Provisional measures under congressional analysis') ? ' Type__c  ASC NULLS LAST, Number__c ASC NULLS LAST ' : ' Sector__c ASC NULLS LAST, Type__c ASC NULLS LAST, Number_Text__c ASC NULLS LAST ' ;

        let result = await queryRecords({ObjectName: objectName,
                                         fields: fields,
                                         filterQuery: filterQuery,
                                         sortQuery: sortQuery});

        //Prepare rows...
        for(let row of result.data){
            //English...
            let rowEnglish = {
                id: row.Id,
                sector: row.Sector__c || '',
                proposal: row.Proposal__c || '',
                type: row.Type__c || '',
                number: ((this.selectedTable=='Provisional measures under congressional analysis') ? row.Number__c : row.Number_Text__c) || '',
                summary: row.Summary__c || '',
                status: row.Status__c || '',
                likelihood: row.Likelihood__c || '',
                likelihoodThisYear: row.Likelihood_this_year__c || '',
                lastModified: (row.LastModifiedDate) ? new Date(row.LastModifiedDate) : null,
                expiration: (row.Expiration_Date__c) ? new Date(row.Expiration_Date__c) : null 
            };

            //Portuguese...
            let rowPortuguese = {
                id: row.Id,
                sector: row.Sector_Portuguese__c || '',
                proposal: row.Proposal_Portuguese__c || '',
                type: row.Type__c || '',
                number: ((this.selectedTable=='Provisional measures under congressional analysis') ? row.Number__c : row.Number_Text__c) || '',
                summary: row.Summary_Portuguese__c || '',
                status: row.Status_Portuguese__c || '',
                likelihood: ((row.Likelihood__c=='Approved') ? 'Aprovado' : row.Likelihood__c)  || '',
                likelihoodThisYear: ((row.Likelihood_this_year__c=='Approved') ? 'Aprovado' : row.Likelihood_this_year__c)  || '',
                lastModified: (row.LastModifiedDate) ? new Date(row.LastModifiedDate) : null,
                expiration: (row.Expiration_Date__c) ? new Date(row.Expiration_Date__c) : null 
            }

            //Add to data object by language...
            this.data.English.push(rowEnglish);
            this.data.Portuguese.push(rowPortuguese);
        }

        //toggle sort to make sure sort is defaulted and consistent via localcompare
        this.sort();
        this.sort();
        
        this.showSpinner = false;
    }

     sort(event){
        this.showSpinner = true;

        const column = event?.currentTarget?.dataset?.column || ((this.selectedTable=='Provisional measures under congressional analysis') ? 'number' : 'sector');

        if(this.sortBy!=column){
            this.sortDirection = 'asc';            
        } else {
            this.sortDirection = (this.sortDirection=='asc') ? 'desc' : 'asc';
        }
        this.sortBy = column;

        if(this.sortBy=='expiration' || this.sortBy=='lastModified'){
            this.data.English.sort((a, b) => a[this.sortBy] - b[this.sortBy]);
            this.data.Portuguese.sort((a, b) => a[this.sortBy] - b[this.sortBy]);
        } else if(this.sortBy=='sector'){
            //sort by number as tertiary...
            this.data.English.sort((a, b) => a['number'] - b['number']);
            this.data.Portuguese.sort((a, b) => a['number'] - b['number']);
            //sort by number as secondary
            this.data.English.sort((a, b) => a['type'] && b['type'] ? a['type'].localeCompare(b['type']) : !a['type'] - !b['type']);
            this.data.Portuguese.sort((a, b) => a['type'] && b['type'] ? a['type'].localeCompare(b['type']) : !a['type'] - !b['type']);    
            //sort by selected column (primary)
            this.data.English.sort((a, b) => a[this.sortBy] && b[this.sortBy] ? a[this.sortBy].localeCompare(b[this.sortBy]) : !a[this.sortBy] - !b[this.sortBy]);
            this.data.Portuguese.sort((a, b) => a[this.sortBy] && b[this.sortBy] ? a[this.sortBy].localeCompare(b[this.sortBy]) : !a[this.sortBy] - !b[this.sortBy]);    
        } else if(this.sortBy=='type'){
            //sort by number as secondary
            this.data.English.sort((a, b) => a['number'] - b['number']);
            this.data.Portuguese.sort((a, b) => a['number'] - b['number']);
            //sort by selected column (primary)
            this.data.English.sort((a, b) => a[this.sortBy] && b[this.sortBy] ? a[this.sortBy].localeCompare(b[this.sortBy]) : !a[this.sortBy] - !b[this.sortBy]);
            this.data.Portuguese.sort((a, b) => a[this.sortBy] && b[this.sortBy] ? a[this.sortBy].localeCompare(b[this.sortBy]) : !a[this.sortBy] - !b[this.sortBy]);    
        } else if(this.sortBy=='number'){
            if(this.selectedTable=='Provisional measures under congressional analysis'){
                //number data type
                this.data.English.sort((a, b) => a[this.sortBy] - b[this.sortBy]);
                this.data.Portuguese.sort((a, b) => a[this.sortBy] - b[this.sortBy]);
            } else {
                //text data type
                this.data.English.sort((a, b) => a[this.sortBy] && b[this.sortBy] ? a[this.sortBy].localeCompare(b[this.sortBy]) : !a[this.sortBy] - !b[this.sortBy]);
                this.data.Portuguese.sort((a, b) => a[this.sortBy] && b[this.sortBy] ? a[this.sortBy].localeCompare(b[this.sortBy]) : !a[this.sortBy] - !b[this.sortBy]);        
            }
        } else {
            this.data.English.sort((a, b) => a[this.sortBy] && b[this.sortBy] ? a[this.sortBy].localeCompare(b[this.sortBy]) : !a[this.sortBy] - !b[this.sortBy]);
            this.data.Portuguese.sort((a, b) => a[this.sortBy] && b[this.sortBy] ? a[this.sortBy].localeCompare(b[this.sortBy]) : !a[this.sortBy] - !b[this.sortBy]);    
        }

        if(this.sortDirection=='desc'){
            this.data.English.reverse();
            this.data.Portuguese.reverse();
        }

        this.showSpinner = false;
    }
    
    download(event){
        let table = (this.selectedTable=='Provisional measures under congressional analysis') ? '2' : '1';
        let page = '/bct_csv?table=' + table + '&lang=' + ((this.selectedLanugage=='Portuguese') ? 'pt-br' : 'en-us');
        window.open(page, '_blank');
    }
}