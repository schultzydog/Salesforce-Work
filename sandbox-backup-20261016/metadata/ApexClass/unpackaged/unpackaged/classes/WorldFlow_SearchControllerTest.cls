/*
* Test class for  WorldFlow_SearchController and WorldFlow_ApiUtils
*/
@isTest
private class WorldFlow_SearchControllerTest {
    
    @testSetup 
    private static void setup() {
        //Set custom setting if not set already
        if(WorldFlowAPISetting__c.getInstance() == null){
            insert new WorldFlowAPISetting__c(
                SetupOwnerId = UserInfo.getOrganizationId()
                , Base_Url__c = 'http://google.com' 
                , Username__c = 'test'
                , Password__c = 'test'
                , Unique_Id__c = 'test'
            );
        }    
    }

    
    @isTest
    private static void testSearchController(){
        Test.setMock(HttpCalloutMock.class, new WorldFlow_SearchControllerTest.MockHttpResponse());

        //Load  Search Param
        WorldFlow_SearchController.getSearchParams();

        //Search 
        WorldFlow_SearchController.search('Test', new List<String>{'Asia','Europe'}, new List<String>{'USA','CHI'} 
                                        ,  new List<String>{'tag1','tag2'} ,  new List<String>{'author1','author2'}
                                         , 1, 'ALL');

        //Download Seearch Result 
        WorldFlow_SearchController.getResearchFile('Test','HTML');
        WorldFlow_SearchController.getResearchFile('Test','PDF');

        ApexPages.currentPage().getParameters().put('code','test');
        ApexPages.currentPage().getParameters().put('type','html');
        WorldFlow_SearchController obj = new WorldFlow_SearchController();
        System.assertEquals(obj.contentType , 'html');
        System.assertEquals(obj.articleHTML ,'html');
        System.assertEquals(obj.pdf, EncodingUtil.Base64Encode( Blob.valueOf('html')));
    }


   
    public class MockHttpResponse implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            //System.assertEquals('https://example.com/example/test', req.getEndpoint());
            //System.assertEquals('GET', req.getMethod());

            String responseBody = '{"authenticationToken":{"token": "test", "userId": "test"}}';

            String endpoint = req.getEndpoint();
            if(endPoint.containsIgnoreCase('getResearchFile')){//Download file
                responseBody = 'html';
            }
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }


}