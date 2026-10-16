/*
* This class executed Post Sandbox refresh to setup initial data in Sandbox
*/
global class PostSandboxRefreshScript implements SandboxPostCopy {

    final string LIBRARY_CATEGORY_FILE = 'SANDBOX_REFRESH_LIBRARY_DLC';
    final string LIBRARY_SUBCATEGORY_FILE = 'SANDBOX_REFRESH_LIBRARY_DLSUBCAT';
    final string LIBRARY_DL_FILE = 'SANDBOX_REFRESH_LIBRARY_DL';
    final string EGPROJECT_FILE = 'SANDBOX_REFRESH_PROJECT';
    final string EGPROJECT_TASKS_FILE = 'SANDBOX_REFRESH_PROJECT_TASK';
    Map<String,Id> recordTypeMapping = new Map<String,Id>();

    global PostSandboxRefreshScript() {

    }

    global void runApexClass(SandboxContext context) {
        
        this.loadDefaultData();
    }

    private void loadDefaultData(){
        //Fetch Record Types 
        for(RecordType rt : [SELECT Id,DeveloperName FROM RecordType Where sObjectType = 'Library__c']){
            recordTypeMapping.put(rt.DeveloperName, rt.Id);
        }
        //For Librabry__c 
       Map<String,Schema.DisplayType> mapLibraryFields = this.getLibrabryFieldMap();
        Map<String,sObject> mapLibrary = new Map<String,sobject>();
        //Create Library - Categories & Portal Region/Sector Permissions
        Map<String,sObject> librabries = this.createRecords(mapLibraryFields, null, null,LIBRARY_CATEGORY_FILE);
        mapLibrary.putall(librabries);
        //Create Library - Sub Categories
        librabries = this.createRecords(mapLibraryFields, mapLibrary, new List<String>{'Distribution_List_Category__c'}, LIBRARY_SUBCATEGORY_FILE);
        mapLibrary.putall(librabries);
        //Create Library - DL
        librabries = this.createRecords(mapLibraryFields, mapLibrary, new List<String>{'Distribution_List_Category__c','Distribution_List_SubCategory__c'}, LIBRARY_DL_FILE);
        mapLibrary.putall(librabries);

       //Create EG Projects
        Map<String,sObject> egProjects = this.createRecords(this.getProjectFieldMap(), null, null, EGPROJECT_FILE);
        //Create EG Project Tasks
        this.createRecords(this.getProjectTaskFieldMap(), egProjects, new List<String>{'EG_Project__c'}, EGPROJECT_TASKS_FILE);
        
    }
//
//
//
	private Map<String,Schema.DisplayType> getProjectFieldMap(){
        Map<String,Schema.DisplayType> mapFields = new Map<String,Schema.DisplayType>();
        for(Schema.SObjectField field : Schema.SObjectType.EG_Project__c.fields.getMap().values()){
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if(dfr.isCreateable()){
                mapFields.put(dfr.getName().toUpperCase(), dfr.getType());
            }
        }
        //system.debug('--mapFields' + mapFields);
        return mapFields;
    }
    
    private Map<String,Schema.DisplayType> getProjectTaskFieldMap(){
        Map<String,Schema.DisplayType> mapFields = new Map<String,Schema.DisplayType>();
        for(Schema.SObjectField field : Schema.SObjectType.EG_Project_Task__c .fields.getMap().values()){
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if(dfr.isCreateable()){
                mapFields.put(dfr.getName().toUpperCase(), dfr.getType());
            }
        }
        //system.debug('--mapFields' + mapFields);
        return mapFields;
    }
//
//
//
   private Map<String,Schema.DisplayType> getLibrabryFieldMap(){
        Map<String,Schema.DisplayType> mapFields = new Map<String,Schema.DisplayType>();
        for(Schema.SObjectField field : Schema.SObjectType.Library__c.fields.getMap().values()){
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if(dfr.isCreateable()){
                mapFields.put(dfr.getName().toUpperCase(), dfr.getType());
            }
        }
        //system.debug('--mapFields' + mapFields);
        return mapFields;
    }
        
    private Map<String,sObject> createRecords(Map<String,Schema.DisplayType> mapFields, Map<String,sObject> parentMap
                                              , List<String> referencedFields, String dataFileName){
       
        StaticResource sr = [SELECT
                                 Id,NamespacePrefix,SystemModstamp,Name,Body 
                            FROM 
                                StaticResource 
                            WHERE 
                                Name = : dataFileName 
                                AND NamespacePrefix = null LIMIT 1];
        
        String body = sr.Body.toString();//pg.getContent().toString();
                                                  
        //system.debug('--body: ' + body);
        CSVReader bodykpi = new CSVReader(body);
        String[] fields = bodykpi.readLine();
        //Load the next line in a variable
        String[] line = bodykpi.readLine();
        Map<String,sObject> records = new Map<String,sObject> ();
        Integer index = 1;
                                                  
        While (line != null && index <= 2000){
           
            //system.debug('--line: ' + line);
            if(dataFileName == EGPROJECT_FILE){
                this.addRecord(records, new EG_Project__c(), line, fields, mapFields);
            }else if(dataFileName == EGPROJECT_TASKS_FILE){
                this.addRecord(records, new EG_Project_Task__c(), line, fields, mapFields);
            }else{
                this.addRecord(records, new Library__c(), line, fields, mapFields);
            }
             
                
            
        	index++;
       		line = bodykpi.readLine();
        }
        // Last line if not null
        //this.addRecord(records, new Library__c(), line, fields, mapFields);    
                                                  
        if(referencedFields != null && parentMap != null){
            this.updateRefernceFields(records.values(), parentMap, referencedFields);//new List<String>{'Distribution_List_Category__c','Distribution_List_SubCategory__c'});
        }
                                                  
                                                
        Database.insert (records.values(), false);

        return records;
    }

    private void updateRefernceFields(List<sObject> objectList, Map<String, sObject> parentObjectList, List<String> fieldNames){
        for(sObject obj : objectList){
            for(String field : fieldNames){
                //system.debug('--' + field + ' : '  + obj);
                //system.debug('--' + field + ' : '  + obj.get(field));
                if(obj.get(field) != null && parentObjectList.containsKey(String.valueOf(obj.get(field)))){
                    //system.debug('--' + field + ' : '  + parentObjectList.get(String.valueOf(obj.get(field))).Id);
                    obj.put(field, parentObjectList.get(String.valueOf(obj.get(field))).Id);
                }
            }
        }
    }  
    
    private void addRecord(Map<String, sObject> objectList, sObject obj, String[] line, String[] fields, Map<String,Schema.DisplayType> mapFields){
        if(line != null){
            Integer index = 0;
            String uniqueId = '';
            for(String field : fields){
               // system.debug('--field' + field);
               // system.debug('--line[index]' + line[index]);
                if(field == 'Id'){
                    uniqueId = line[index];
                }
                //RECORD_TYPE_NAME__C
                else if(field == 'RECORDTYPE.DEVELOPERNAME'){
                    String recordTypeId = recordTypeMapping.get(line[index]);
                    if(String.isNotBlank(recordTypeId)){
                        obj.put('RecordTypeId', recordTypeId);
                    }
                }
                else if(mapFields.containskey(field.toUpperCase())){
                    object value = null;//(Object)(line[index]);
                    Schema.DisplayType dfr = mapFields.get(field.toUpperCase());
                   // system.debug('--dfr' + dfr);
                    if(dfr == Schema.DisplayType.LONG
                       || dfr == Schema.DisplayType.INTEGER
                       || dfr == Schema.DisplayType.PERCENT
                       || dfr == Schema.DisplayType.CURRENCY
                       || dfr == Schema.DisplayType.DOUBLE){
                       value = (String.isBlank(line[index])) ? 0 : Decimal.valueOf(line[index]);
                    }else if(dfr == Schema.DisplayType.BOOLEAN){
                       value = (String.isBlank(line[index])) ? false : Boolean.valueOf(line[index]);
                    }else {
                       value = line[index];
                    }
                   // system.debug('-- field ' + field );
                    //    system.debug('-- dfr ' + dfr );
                    if(dfr != null){
                    	obj.put(field, value);
                    }
                }
                index ++;
            }
              system.debug('--obj: ' + obj);
        	objectList.put(uniqueId, obj);            
        }       
    }




    public class CSVReader {
        private String delim = ',';
        // the input data
        private String[] buffer;
        
        public CSVReader(String data){
            this.buffer = data.split('\n'); 
        }
        
        public CSVReader(String data, String delim){
            this.buffer = data.split('\n'); 
            this.delim = delim;
        }
        
        /**
         * Read and parse next available line.  Return null if end of stream.
         */
        public String[] readLine(){
            if(buffer.size() == 0)
                return null;
            String line = this.buffer.remove(0);
            String[] parts = new String[] {};
            while(line != ''){
                Integer next = 0;
                if(line.startsWith('"')){
                    line = line.substring(1); // strip initial
                    Integer quoteIndex = findQuote(line, 0);
                    while(quoteIndex == -1){
                        if(buffer.size() == 0){
                            // EOT!
                            quoteIndex = line.length();
                        } else { 
                            // grab the next line
                            Integer skip = line.length();
                            line += '\n' + this.buffer.remove(0);
                            quoteIndex = findQuote(line, skip);
                        }
                    }
                    // advance to comma
                    next = quoteIndex + 1;
                    parts.add(line.substring(0, quoteIndex).replace('""', '"'));
                } else {
                    next = line.indexOf(this.delim, next);
                    if(next == -1)
                        next = line.length();
                    // NB in Substring, "endindex" is the index of the character AFTER the last index to get
                    parts.add(line.substring(0, next));
                }		
                if(next == line.length() - 1)
                    // case of a terminating comma.
                    parts.add('');
                line = next < line.length() ? line.substring(next+1) : '';
            }
            if(parts.size() == 0)
                // empty string - we still want to return something...
                parts.add('');
            return parts;
        }
        
        private Pattern quotePattern = Pattern.compile('(?<!")"(?!")');
        /**
         * Find next quote in the line
         */
        private Integer findQuote(String line, Integer skip){
            Matcher m = quotePattern.matcher(line);
            m.region(skip, m.regionEnd());
            if(!m.find())
                return -1;
            return m.start();
        }
    }
}