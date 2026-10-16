/**************************************************************************************
 * @Date: 05/18/2022
 * @Name: egRelatedListController
 * @Description: This is a controller class for egRelatedList ightning Web Componnet
 *              - This has method for Search, and Related list (Query + Info)
 **************************************************************************************/

public without sharing class egRelatedListController {   
  
   

   //Field Type Map - Conversion of Field DisplayTypeEnum to LWC data table type
   static Map<String,String> fieldTypeMappings
            = new Map<String,String>{
                    'ADDRESS'=>'location',  'ANYTYPE'=>'textDataType',
                    'BASE64'=>'textDataType',  'BOOLEAN'=>'boolean',
                    'COMBOBOX'=>'textDataType','CURRENCY'=>'currency',
                    'DataCategoryGroupReference'=>'textDataType',
                    'DATE'=>'dateDataType', 'DATETIME'=>'dateDataType',
                    'DOUBLE'=>'number', 'EMAIL'=>'email', 'EncryptedString'=>'textDataType',
                    'ID'=>'textDataType', 'Integer'=>'number',
                    'LONG'=>'number','MULTIPICKLIST'=>'textDataType',
                    'PERCENT'=>'percent','PHONE'=>'phone',  'PICKLIST'=>'textDataType',
                    'REFERENCE'=>'url','STRING'=>'textDataType','TEXTAREA'=>'textDataType',
                    'TIME'=>'time','URL'=>'url' 
                    , 'HTML' => 'htmlDataType'};

     /**************************************************************************************
   * @Description:  Lookup Search function, to query on Contact object and return it.
   * @Param:		String - objectName - Object API Name
   * @Param:		String - fieldNames - Comma seperated field API Name
   * @Return:      Map   -  Object and field information used in LWC component to bind data table 
   * @Example:     
   * EmployeeHomePageController.getObjectInfo('Contact','Name,Email,FirstName')
   **************************************************************************************/
   @AuraEnabled
   public static Map<String,Object> getObjectInfo(String objectName, String fieldNames){
        List<Object> fieldDetails = new List<Object>();
        Schema.DescribeSObjectResult sobjectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
        for(string field : fieldNames.split(',')){
            field = field.trim();
            
            if(field.contains('.')){//For one level parent
                system.debug('-reference Field-' +  field);
                String[] referencedFields = field.split('\\.');
                //Find refernce fields
                system.debug('-referencedFields-' +  referencedFields);
                String parentfieldAPIName = referencedFields[0];
                if(!parentfieldAPIName.endsWith('__c')){
                    parentfieldAPIName += 'Id';
                }
                Map <String, Schema.SObjectField> fieldMap = sobjectDescribe.fields.getMap(); 
                if(fieldMap.containsKey(parentfieldAPIName)){
                    schema.describefieldresult fieldSchema = fieldMap.get(parentfieldAPIName).getDescribe();
                    List<Schema.sObjectType> referenceTo = fieldSchema.getReferenceTo();
                    Schema.DescribeSObjectResult referenceDescribe = referenceTo[0].getDescribe();
                    fieldDetails.add(
                        getFieldDetails(
                            referenceDescribe
                            , referencedFields[1]
                            , referenceDescribe.getName()+'_'
                            , referenceDescribe.getName()
                            , (referenceDescribe.isCustom() ?  referenceDescribe.getLabel() : referenceDescribe.getName())
                        )
                    );
                }
            }else{
                fieldDetails.add(
                    getFieldDetails(
                        sobjectDescribe
                        , field
                        , ''
                        , 'recordId'
                        , ''
                    )
                );
            }
        }
        
       return new Map<String,Object>{
            'label' => sobjectDescribe.getLabelPlural()
            , 'fields' => fieldDetails
        };

   }
   public static Object getFieldDetails(Schema.DescribeSObjectResult sobjectDescribe, String field, String namePrefix, String IdField, String labelPrefix){  
        if(labelPrefix == 'Product2'){
            labelPrefix = 'Product';
        }
       System.debug('field-' + field);
       System.debug('sobjectDescribe-' + sobjectDescribe.getName());
       Map <String, Schema.SObjectField> fieldMap = sobjectDescribe.fields.getMap(); 
       Map<String, Object> columnInfo; 
       for(String s : fieldMap.keySet()){
        System.debug('fieldMap-' + s); 
       }
                     
           if(fieldMap.containskey(field)){
               //If Field is accessible per Security model
               schema.describefieldresult fieldSchema = fieldMap.get(field).getDescribe();
               system.debug('field Type > ' + fieldSchema);
               //if(fieldSchema.isAccessible()){
                   //{label: 'Opportunity name', fieldName: 'opportunityName', type: 'text'},
                   system.debug('field Type > ' + fieldTypeMappings.get(fieldSchema.getType().name()));
                   system.debug('field Type > ' + fieldSchema.getType().name());
                   
                   string fieldType = fieldTypeMappings.get(fieldSchema.getType().name());
                   columnInfo 
                       = new Map<String, Object>{
                           'label' => fieldSchema.getLabel()
                           , 'fieldName' => namePrefix + fieldSchema.getName()
                           , 'hideDefaultActions' => true
                           ,  'type' => fieldTypeMappings.get(fieldSchema.getType().name())
                   };
                    
                   if(fieldSchema.getName() == 'Name'){
                       system.debug('-labelPrefix-'+ labelPrefix);
                       
                       string urlfieldName  = namePrefix + 'Name';
                       columnInfo.put('typeAttributes', JSON.deserializeUntyped('{"label":{"fieldName": "'+ urlfieldName + '"}, "tooltip":{"fieldName": "'+ urlfieldName + '"}}'));
                       columnInfo.put('fieldName',IdField );
                       columnInfo.put('type', 'url' );
                       //Only for Contact
                       if(String.isNotBlank(labelPrefix)){
                        columnInfo.put('label',labelPrefix );
                       }else if(! sobjectDescribe.isCustom()){
                            columnInfo.put('label', fieldSchema.getLocalName());
                        } 
                       
                   }else if(fieldSchema.getType() == Schema.DisplayType.REFERENCE){
                       //getRelationshipName
                       string urlfieldName  = field + '_Name';
                       columnInfo.put('typeAttributes'
                            , JSON.deserializeUntyped('{"label":{"fieldName": "'+ urlfieldName + '"}, "tooltip":{"fieldName": "'+ urlfieldName + '"}}'));
                       columnInfo.put('fieldName', fieldSchema.getRelationshipName() );
                       
                   }else if(fieldSchema.getName().toLowerCase().startsWith('html')){
                       //columnInfo.put('typeAttributes', JSON.deserializeUntyped('{ "recordId":test,"htmlValue":"_blank"}'));
                       columnInfo.put('type', 'htmlDataType' );
                       
                   }
                   
                   
              // }
        }/*else if(field.contains('.')){//For one level parent
                String[] referencedFields = field.trim().split('.');
                //Find refernce fields
                String parentfieldAPIName = referencedFields[0];
                if(!parentfieldAPIName.endsWith('__c')){
                    parentfieldAPIName += 'Id';
                }

                if(fieldMap.containsKey(parentfieldAPIName)){

                }
           }*/
       
       return columnInfo;
   }

   /**************************************************************************************
   * @Description:  Lookup Search function, to query on Contact object and return it.
   * @Param:		String - searchTerm - Seach Keywords
   * @Return:       List   - Search result from Contact object. 
   * @Example:     
   * EmployeeHomePageController.search('John')
   **************************************************************************************/
   @AuraEnabled
   public static Map<String,Object> queryRecords(String ObjectName
                                               , String fields
                                               , String filterQuery
                                               , String parentField
                                               , String parentId
                                               , String sortQuery) {
       
       String SelectQuery = 'SELECT Id ';
       for(String field : fields.split(',')){
           SelectQuery += ' , ' + string.escapeSingleQuotes(field);
       }
       String formQuery = ' FROM ' + string.escapeSingleQuotes(objectName);
       String whereQuery = ' WHERE Id != null ';
       
       if(String.isNotBlank(filterQuery)){
           whereQuery += ' AND ' + filterQuery;
       }

       if(String.isNotBlank(parentField) && String.isNotBlank(parentId)){
           whereQuery += ' AND ' + string.escapeSingleQuotes(parentField) + ' =: parentId';
       }
       
       if(String.isNotBlank(sortQuery)){
           sortQuery = ' Order BY  ' + sortQuery;
       }else{
           sortQuery = ' Order By CreatedDate desc ';
       }
       System.debug('--rows--' + 'SELECT count() ' + formQuery + whereQuery);
       System.debug('--count--' + SelectQuery + formQuery + whereQuery + sortQuery );
       return new Map<String,Object>{
           'data' => Database.query(SelectQuery + formQuery + whereQuery + sortQuery)
       };
   }

   
}