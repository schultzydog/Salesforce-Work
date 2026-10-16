/**
 * @description       : MultiSelectLookupController
**/
public with sharing class MultiSelectLookupController {
    //This method retrieves the data from database table. It search input is '*', then retrieve all records
    @AuraEnabled (cacheable=true)
    public static List<SObjectQueryResult> retrieveRecords(String objectName, 
                                                    String fieldAPINames,
                                                    String filterFieldAPIName,
                                                    String strInput,
                                                    String staticFilter,
                                                    String filterParentAPIName,
                                                    List<String> filterParentIds){
        
        List<SObjectQueryResult> lstReturnResult = new List<SObjectQueryResult>();
        if(strInput.equals('*')){
            strInput = '';
        }
        String str = strInput + '%';
        String strQueryField = '';
        List<String> fieldList = fieldAPINames.split(',');

        //check if Id is already been passed
        if(!fieldList.contains('Id')){
            fieldList.add('Id');
            strQueryField = String.join(fieldList, ',');
        }else {
            strQueryField = fieldAPINames;
        }

        String strQuery = 'SELECT ' + String.escapeSingleQuotes(strQueryField) 
                        + ' FROM ' 
                        + String.escapeSingleQuotes(objectName) 
                        + ' WHERE ' 
                        
                        + ( 
                                (objectName == 'User' || objectName == 'Contact') 
                                    ? 
                                        ' ( FirstName like \'' + str + '%\' OR  LastName  like \'' + str + '%\') ' 
                                    : 
                                        filterFieldAPIName + '  LIKE \'' + str + '%\''
                         )
                        
                        + (String.isNotBlank(staticFilter) ? ' AND ' + staticFilter : ''  )
                        + (String.isNotBlank(filterParentAPIName) 
                            ?  (' AND ' + filterParentAPIName + '  IN : filterParentIds ') 
                            : '')
                        + ' ORDER BY ' + filterFieldAPIName
                        + ' LIMIT 50';
                        
        System.debug('strQuery=' + strQuery);

        List<SObject> lstResult = database.query(strQuery);
        //create list of records that can be easily be parsable at js controller.
       /* for(String strField:fieldList){
            for(SObject sobj:lstResult){                
                if(strField != 'Id'){
                    lstReturnResult.add( new SObjectQueryResult(sobj, filterFieldAPIName, objectName));
                }                
            }
        }*/
        for(SObject sobj:lstResult){                
            //if(strField != 'Id'){
                lstReturnResult.add( new SObjectQueryResult(sobj, filterFieldAPIName));
            //}                
        }
        return lstReturnResult;
    }
    
    public class SObjectQueryResult {
        @AuraEnabled
        public String recordId;

        @AuraEnabled
        public String recordName;

        @AuraEnabled
        public SObject record;

        @AuraEnabled
        public String value {
            get {
                return this.recordId;
            }
        }

        @AuraEnabled
        public String label {
            get {
                return this.recordName;
            }
        }


        public SObjectQueryResult(SObject record, String field){
            this.record = record;
            this.recordId = (String) record.get('Id');
            this.recordName = (String) record.get(field);
        }
    }
}