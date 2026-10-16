/**
 *  Utility class for WorkFlow API for Search
 * 
 */
public with sharing class WorldFlow_ApiUtils {

    //Custom Setting for Base URL and Authentication details
    WorldFlowAPISetting__c apiSetting;
    String authToken; //Auth Token
    String userId; //UserId
    Integer loginCount = 0;
    boolean reLogin = false;

    private static WorldFlow_ApiUtils newInstance = new WorldFlow_ApiUtils();

    public static WorldFlow_ApiUtils getInstance(){
        if(newInstance == null){
            newInstance = new WorldFlow_ApiUtils();
        }
        return newInstance;
    }

    private void loadDefault(){
        //Fetch AuthToken and UserId from Cache
        if(Cache.Org.contains('wfAuthToken') && Cache.org.contains('wfUserId')){
            this.authToken = (String)Cache.Org.get('wfAuthToken'); 
            this.userId = (String)Cache.Org.get('wfUserId'); 
        }
    }

    private void saveCache(){
        //Save AuthToken and UserId into Cache
        Cache.org.put('wfAuthToken', authToken);
        Cache.org.put('wfUserId', userId);
    }

    public WorldFlow_ApiUtils() {
        //Fetch Custom setting
        apiSetting = WorldFlowAPISetting__c.getInstance();
    }

    //Search Ressearch
    public String searchResearchs(String searchTxt, List<String> regionCode
                                    ,List<String> countryCode, List<String> tagCode
                                    , List<String> analystCode, integer batchSize
                                    , Integer index
                                    , String dateRange){
        this.login();
        String responseJson;
        String analysts = '';
        String regions = '';
        String countries = '';
        String tags = '';
        if(analystCode != null){
            for(String analyst : analystCode){
                analysts +=  (analysts  != '' ? ', ': '') +  '"' + analyst + '"';   
            }
        }
        if(regionCode != null){
            for(String region : regionCode){
                regions +=  (regions  != '' ? ', ': '') +  '"' + region + '"';   
            }
        }
        if(countryCode != null){
            for(String country : countryCode){
                countries +=  (countries  != '' ? ', ': '') +  '"' + country + '"';   
            }
        }
        if(tagCode != null){
            for(String tag : tagCode){
                tags +=  (tags  != '' ? ', ': '') +  '"' + tag + '"';   
            }
        }


        String requestBody = '{"userResearchSearchWebServiceGetSearchResearchDocumentDTO":'
                                     + '{'
                                        + ' "searchText1": "' + searchTxt + '"'
                                        + ' ,"analyst": [' + analysts + ']'
                                        + ' ,"region": [' + regions + ']'
                                        + ' ,"country": [' + countries + ']'
                                        + ' ,"sector": [' + tags + ']'
                                        + ' ,"batchSize": ' + batchSize +
                                        + ' ,"index": ' + index 
                                        + ' ,"dateRange": "' + dateRange + '"'
                                        + ' ,"sortAttribute": "date"'
                                     + '}'
                            + '}';
        HttpResponse res 
                = this.callout(
                        '/userResearchSearchWebService/taggedSearch'
                        , 'POST'
                        , new Map<String,String>()
                        , requestBody
                        , true);
        if(res.getStatusCode() != 200){
            throw new APIException(res.getStatusCode() + ' Body : ' + res.getBody());
        }
        try{
            System.debug('requestBody - ' + requestBody);
            responseJson = res.getBody();
            System.debug('responseJson - ' + responseJson);
            //Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
            //System.debug('result - ' + result);

            //researchDocumentSearchParameters

            
        }catch(Exception e){
            new APIException(e);
        }

        return responseJson;

    }

    //Get Ressearch File PDF
    public Blob getResearchFile(String code){
        this.login();
        Blob responseJson;
        String requestBody = '{"researchFileRetrievalWebServiceGetResearchDocumentDTO":'
                                     + '{'
                                        + ' "code": "' + code + '"'
                                        + ' ,"documentType": "PDF"'
                                     + '}'
                            + '}';
        HttpResponse res 
                = this.callout(
                        '/researchFileRetrievalWebService/getResearchFile'
                        , 'POST'
                        , new Map<String,String>()
                        , requestBody
                        , true);
        if(res.getStatusCode() != 200){
            throw new APIException(res.getStatusCode() + ' Body : ' + res.getBody());
        }
        try{
            responseJson = res.getBodyAsBlob();
            System.debug('responseJson - ' + responseJson);
            //Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
            //System.debug('result - ' + result);

            //researchDocumentSearchParameters

            
        }catch(Exception e){
            new APIException(e);
        }

        return responseJson;

    }

    //Get Ressearch File PDF
    public String getResearchFileHTML(String code){
        this.login();
        String responseJson;
        String requestBody = '{"researchFileRetrievalWebServiceGetResearchDocumentDTO":'
                                     + '{'
                                        + ' "code": "' + code + '"'
                                        + ' ,"documentType": "HTML"'
                                     + '}'
                            + '}';
        HttpResponse res 
                = this.callout(
                        '/researchFileRetrievalWebService/getResearchFile'
                        , 'POST'
                        , new Map<String,String>()
                        , requestBody
                        , true);
        if(res.getStatusCode() != 200){
            throw new APIException(res.getStatusCode() + ' Body : ' + res.getBody());
        }
        try{
            responseJson = res.getBody();
            System.debug('responseJson - ' + responseJson);
            //Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
            //System.debug('result - ' + result);

            //researchDocumentSearchParameters

            
        }catch(Exception e){
            new APIException(e);
        }

        return responseJson;

    }

    //Fetch Parameters for search
    public String fetchSearchParameters(){
        this.login();
        if(Cache.Org.contains('wfSearchParameters') ){
            return (String)Cache.Org.get('wfSearchParameters');
        }

        String responseJson;
        String requestBody = '{"searchDTO":'
                                     + '{'
                                        + ' "date": "' + DateTime.now().format('yyyy-mm-dd hh:mm') + '"'
                                        + '}'
                            + '}';
        HttpResponse res 
                = this.callout(
                        '/researchDocumentSearchParametersWebService/getResearchDocumentSearchParameters'
                        , 'POST'
                        , new Map<String,String>()
                        , requestBody
                        , true);
        if(res.getStatusCode() != 200){
            throw new APIException(res.getStatusCode() + ' Body : ' + res.getBody());
        }
        try{
            responseJson = res.getBody();
            System.debug('responseJson - ' + responseJson);
            Cache.Org.put('wfSearchParameters',responseJson);
            //Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
            //System.debug('result - ' + result);

            //researchDocumentSearchParameters

            
        }catch(Exception e){
            new APIException(e);
        }

        return responseJson;

    }

    //Authentication callout
    public void login(){
        this.loadDefault();
        if(this.reLogin && this.loginCount == 0){
            this.loginCount += 1;
            this.authToken = null;
            this.userId = null;
        }
        //Validate if Auth Token and UserId is set in the previous callout to avoid unncessary login callout
        if(String.isBlank(authToken) || String.isBlank(userId)){
            String requestBody = '{"authenticationDTO":'
                                        + '{'
                                            + ' "login": "' + apiSetting.Username__c + '"'
                                            + ', "password": "' + apiSetting.Password__c + '"'
                                            + ', "udid": "' + apiSetting.Unique_Id__c + '"'
                                            + ', "rm": true'
                                            + '}'
                                + '}';
            HttpResponse res 
                    = this.callout(
                            '/authenticationWebService/auth'
                            , 'POST'
                            , new Map<String,String>()
                            , requestBody
                            , false);
            if(res.getStatusCode() != 200){
                throw new APIException('Not able to login');
            }
            try{
                String responseJson = res.getBody();
                System.debug('responseJson - ' + responseJson);
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(responseJson);
                Map<String,Object> authenticationToken = (Map<String,Object>)result.get('authenticationToken');
                authToken =  String.valueOf(authenticationToken.get('token'));// Auth Token
                userId =  String.valueOf(authenticationToken.get('userId')); // User Id

                System.debug('authToken - ' + authToken);
                System.debug('userId - ' + userId);
                this.saveCache();
            }catch(Exception e){
                new APIException(e);
            }
        }
        /*{
                "authenticationToken": {
                    "issuedAt": "2022-09-14T07:49:28.780Z",
                    "role": "User",
                    "token": "991552f3-10ba-4540-b8d6-d8545a36851d",
                    "userId": 117560
                }
            }
        */

    }

    //Rest Callout
    private HttpResponse callout(String endPoint, String method, Map<String, String> headers, String body, boolean addAuthHeader){
        Http h = new Http();
        HttpResponse res;
        try{
            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();       
            req.setEndpoint(apiSetting.Base_Url__c + endPoint);
            req.setMethod(method);

            //Add Auth Headers
            if(addAuthHeader){
                req.setHeader('x-wf-user', userId);
                req.setHeader('x-wf-token', authToken);
            }

            // Add Content Type Json for all call except Get
            if(method != 'Get'){
                req.setHeader('Content-Type', 'application/json');
            }

            //Set Headers
            for(String key : headers.keyset()){
                req.setHeader(key, headers.get(key));
            }
            // Set Request Body
            if(String.isNotBlank(body)){
                req.setBody(body);
            }
            // Send the request, and return a response
            res = h.send(req);
        }catch(Exception ex){
            throw new APIException(ex);
        }

        return res;
        
    }

    //Custom Exception for the API callout
    public class APIException extends Exception{}

    public enum Errorcode{
        LOGIN_ERROR
    }


}