@IsTest
private class ContactEnrichmentServiceTest {

    private class StubResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        private StubResponse(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            System.assert(req.getEndpoint().contains('/search.json'), 'Callout should hit SerpAPI search.json');
            System.assert(req.getEndpoint().contains('q='), 'Query should be on the URL');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    @IsTest
    static void enrichParsesKnowledgeGraphAndLinkedIn() {
        Account acct = new Account(Name = 'Eurasia Group');
        insert acct;
        Contact person = new Contact(
            FirstName = 'Jane',
            LastName = 'Analyst',
            AccountId = acct.Id,
            Title = 'Director',
            Email = 'jane@example.com'
        );
        insert person;

        Test.setMock(HttpCalloutMock.class, new StubResponse(200,
            '{"search_information":{"total_results":12},'
                + '"knowledge_graph":{"title":"Jane Analyst","type":"Person",'
                + '"description":"Director at Eurasia Group.","website":"https://www.eurasiagroup.net",'
                + '"source":{"name":"Wikipedia","link":"https://en.wikipedia.org/wiki/Jane"},'
                + '"profiles":[{"name":"LinkedIn","link":"https://www.linkedin.com/in/jane-analyst"}]},'
                + '"organic_results":[{"position":1,"title":"Jane Analyst - Director at Eurasia Group",'
                + '"link":"https://www.linkedin.com/in/jane-analyst",'
                + '"snippet":"Director at Eurasia Group. New York.","displayed_link":"linkedin.com"}]}'
        ));

        Test.startTest();
        ContactEnrichmentService.EnrichmentResult result = ContactEnrichmentService.enrich(person.Id);
        Test.stopTest();

        System.assertEquals('Jane Analyst', result.contact.name);
        System.assert(result.query.contains('Jane Analyst'), result.query);
        System.assertEquals('Jane Analyst', result.knowledgeTitle);
        System.assertEquals(12, result.totalResults);
        System.assertEquals(1, result.sources.size(), 'LinkedIn organic hit should be kept');
        System.assertEquals('linkedin', result.sources[0].kind);

        Boolean sawLinkedIn = false;
        Boolean sawWebsite = false;
        for (ContactEnrichmentService.Fact fact : result.facts) {
            if (fact.key == 'linkedin') {
                sawLinkedIn = true;
                System.assertEquals('https://www.linkedin.com/in/jane-analyst', fact.value);
            }
            if (fact.key == 'website') {
                sawWebsite = true;
            }
        }
        System.assert(sawLinkedIn, 'LinkedIn should surface as a fact');
        System.assert(sawWebsite, 'Website from the knowledge graph should surface');
    }

    @IsTest
    static void enrichThrowsWhenSerpApiFails() {
        Account acct = new Account(Name = 'Eurasia Group');
        insert acct;
        Contact person = new Contact(LastName = 'Analyst', AccountId = acct.Id);
        insert person;

        Test.setMock(HttpCalloutMock.class, new StubResponse(401, '{"error":"Invalid API key"}'));

        AuraHandledException caught;
        Test.startTest();
        try {
            ContactEnrichmentService.enrich(person.Id);
        } catch (AuraHandledException e) {
            caught = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caught, 'HTTP 401 should become AuraHandledException');
    }

    @IsTest
    static void buildQueryUsesNameAccountTitleEmailAndPhone() {
        ContactEnrichmentService.ContactSnapshot snap = new ContactEnrichmentService.ContactSnapshot();
        snap.name = 'Jane Analyst';
        snap.accountName = 'Eurasia Group';
        snap.title = 'Director';
        snap.email = 'jane@example.com';
        snap.phone = '(212) 555-0100';
        snap.mobilePhone = '212-555-0100';

        String query = ContactEnrichmentService.buildQuery(snap);

        System.assertEquals(
            '"Jane Analyst" "Eurasia Group" Director OR "jane@example.com" OR "(212) 555-0100" OR "2125550100"',
            query
        );
    }
}