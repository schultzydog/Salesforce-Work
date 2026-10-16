public without sharing class bct_csv_ctlr {

    public String table {public get; private set;}
    public String lang {public get; private set;}
    public String headers {public get; private set;}
    public String contentType {public get; private set;}
    public List<BCT__c> rows {public get; private set;}

    public bct_csv_ctlr() {
        //get query string params...
        String tableParam = ApexPages.currentPage().getParameters().get('table');
        String langParam = ApexPages.currentPage().getParameters().get('lang');

        //validate params...
        if(tableParam=='1'){
            table = 'Main legislative proposals in congress'; //table1
        } else if(tableParam=='2'){
            table = 'Provisional measures under congressional analysis'; //table2
        } else {
            table = 'Main legislative proposals in congress'; //table1
        }

        if(langParam=='en-us' || langParam=='pt-br'){
            lang = langParam;
        } else {
            lang = 'en-us';
        }

        //Prepare headers...
        if(lang=='pt-br'){ 
            //Portuguese
            if(table=='Provisional measures under congressional analysis'){ //table2
                headers = 'Número,Resumo,Status,Expiração'; 
            } else { //table1
                headers = 'Setor,Proposta,Tipo,Número,Resumo,Status,Probabilidade de aprovação em ' + System.Label.BCT_Year + ',Atualizada'; //Probabilidade de aprovação em 9999,
            }
        } else {
            //English
            if(table=='Provisional measures under congressional analysis'){ //table2
                headers = 'Number,Summary,Status,Expiration'; 
            } else { //table1
                headers = 'Sector,Proposal,Type,Number,Summary,Status,Likelihood of approval in ' + System.Label.BCT_Year + ',Updated'; //Likelihood of approval in 9999,
            }
        }

        //set contentType and filename...
        contentType = 'text/csv#EG_';
        if(lang=='pt-br'){
            if(table=='Provisional measures under congressional analysis'){ //table2
                contentType += 'Medidas_provisórias_em_tramitação_no_Congresso_';
            } else { //table1
                contentType += 'Principais_projetos_no_Congresso_';
            }
        } else {
            if(table=='Provisional measures under congressional analysis'){ //table2
                contentType += 'Provisional_measures_under_congressional_analysis_';
            } else { //table1
                contentType += 'Main_legislative_proposals_in_congress_';
            }
        }
        contentType += Datetime.now().formatGMT('yyyy-MM-dd\'T\'HHmm');
        contentType += '.csv';

        //Get records...
        String objectName = ' BCT__c ';
        String fields = ' Table__c, Sector__c, Sector_Portuguese__c, Summary__c, Proposal__c, Proposal_Portuguese__c, Type__c, Number__c, Number_Text__c, Likelihood_of_approval__c, Likelihood__c, Likelihood_this_year__c, LastModifiedDate, Status__c, Summary_Portuguese__c, Status_Portuguese__c, Expiration_Date__c ';
        String filterQuery = ' Publish__c = TRUE AND Table__c = \'' + table + '\' ';
        String sortQuery = (table=='Provisional measures under congressional analysis') ? ' Type__c ASC NULLS LAST, Number__c ASC NULLS LAST ' : ( ((lang=='pt-br') ?  'Sector_Portuguese__c ':' Sector__c ') + 'ASC, Type__c ASC NULLS LAST, Number_Text__c ASC NULLS LAST  ') ;

        rows = (List<BCT__c>)egRelatedListController.queryRecords(objectName, fields, filterQuery, null, null, sortQuery).get('data');

        //Prepare rows...
        for(BCT__c row : rows){
            //If Portuguese, move portuguese values in place...
            if(lang=='pt-br'){ 
                row.Sector__c = row.Sector_Portuguese__c;
                row.Proposal__c = row.Proposal_Portuguese__c;
                row.Summary__c = row.Summary_Portuguese__c;
                row.Status__c = row.Status_Portuguese__c;
                //row.Likelihood__c = ((row.Likelihood__c=='Approved') ? 'Aprovado' : row.Likelihood__c);
            }
        }
    }
}