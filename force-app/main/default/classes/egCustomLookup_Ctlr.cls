public with sharing class egCustomLookup_Ctlr {
    
	@AuraEnabled(cacheable=true)
	public Static List<sObject> searchApex(String type, String queryString, String filterField, String filterValue, String additionalParams){
        system.debug('egCustomLookup_Ctlr searchApex: ');
        system.debug('type: ' + type);
        system.debug('queryString: ' + queryString);
        system.debug('filterField: ' + filterField);
        system.debug('filterValue: ' + filterValue);
        system.debug('additionalParams: ' + additionalParams);

        //Build SOQL query...
        String soql = 'SELECT ID, Name FROM ' + type ;

        //Outlook Event Review narrows the empty project search to the row's Account so
        //opening the box lists that Account's active projects. Typing still searches
        //every project by name, which is why the Account filter is empty-search only.
        Boolean accountScopedProject = type=='EG_Project__c' && filterField=='Account__c';
        Boolean browseAccountProjects = accountScopedProject
            && String.isNotBlank(filterValue)
            && String.isBlank(queryString);

        String whereClause = '';
        if(!String.isBlank(queryString)){
            //add wildcard tokens to queryString...
            String wildcardQueryString = '%' + String.escapeSingleQuotes(queryString).replaceAll('%','') + '%';

            //things to search using queryString... Always search Name...
            whereClause += ' Name LIKE \'' + wildcardQueryString + '\' AND '; //trailing AND may or may not be used
        }

        //additional filter by filterField = filterValue...
        if(filterField!=null && filterValue!=null && (!accountScopedProject || browseAccountProjects)) {
            whereClause += filterField + ' = \'' + filterValue + '\' AND '; //trailing AND may or may not be used
        }

        //handle additional criteria based on sObject type...
        if(type=='EG_Project__c'){

            if(String.isBlank(queryString) && !browseAccountProjects){
                //only show Internal Projects when we don't have a search term, otherwise show all projects that match search term regardless of Internal/External... (Adam email 4/28/2026)
                whereClause += ' Internal_Project__c = TRUE AND ';
            } 

            whereClause += ' (Status__c = \'Active\' ';

            if(String.isNotBlank(additionalParams)){
                //Status = Active OR Timesheet week overlaps in any part with Contract Start Date and Contract End Date...
                List<String> dates = additionalParams.split(',');
                String weekStartDate = dates[0];
                String weekEndDate = dates[1];
                whereClause += ' OR (Contract_Start_Date__c <= ' + weekEndDate + ' AND Contract_End_Date__c >= ' + weekStartDate + ') ';
            }

            whereClause += ') AND '; //trailing AND may or may not be used
        } else if(type=='EG_Project_Task__c'){
            whereClause += ' Status__c = \'Active\' AND '; //trailing AND may or may not be used
        } else if(type=='User'){
            whereClause += ' isActive = TRUE AND ContactId = NULL AND '; //trailing AND may or may not be used
        }

        //append whereClause if we have one...
        if(String.isNotBlank(whereClause)){
            soql += ' WHERE ' + whereClause.left(whereClause.length()-4); //peel of trailing "AND "
        }

        //Order By...
        if(type=='EG_Project__c'){
            soql += ' ORDER BY Is_Internal__c, NAME LIMIT 100';
        } else {
            soql += ' ORDER BY NAME LIMIT 100';
        }

        //Perform query...
        List<sObject> results = Database.query(soql);

        if(String.isNotBlank(queryString)){
            List<sObject> startsWithList = new List<sObject>();
            List<sObject> containsList = new List<sObject>();
            for(sObject result : results){
                String resultName = ((String)result.get('Name'));
                if(resultName.startsWithIgnoreCase(queryString) || resultName.startsWithIgnoreCase('[' + queryString)){ //helper for [Internal]
                    startsWithList.add(result);
                } else {
                    containsList.add(result);
                }
            }
            system.debug('startsWithList: ' + startsWithList);
            system.debug('containsList: ' + containsList);
            if(!containsList.isEmpty()) startsWithList.addAll(containsList);

            results = startsWithList;
        }

		return results;        
    }

}
