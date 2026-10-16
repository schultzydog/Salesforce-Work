@IsTest
private class KnowBe4ClientTest {

    private class StubResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        private StubResponse(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            System.assert(
                req.getEndpoint().contains('per_page=500'),
                'Page size should be passed through to KnowBe4'
            );
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    @IsTest
    static void returnsBodyOnSuccess() {
        Test.setMock(HttpCalloutMock.class, new StubResponse(200, '[{"enrollment_id":1}]'));

        Test.startTest();
        String body = KnowBe4Client.fetchEnrollments(1, KnowBe4Client.MAX_PAGE_SIZE);
        Test.stopTest();

        System.assertEquals('[{"enrollment_id":1}]', body, 'Response body should be returned as-is');
    }

    /** Accepts any page size, unlike StubResponse. */
    private class AnyPageStub implements HttpCalloutMock {
        private String body;
        private AnyPageStub(String body) {
            this.body = body;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(body);
            return res;
        }
    }

    @IsTest
    static void summarizeCountsOnlyRowsOnOrAfterCutoff() {
        Test.setMock(HttpCalloutMock.class, new StubResponse(200,
            '[{"enrollment_id":1,"enrollment_date":"2024-06-01T00:00:00.000Z"}'
                + ',{"enrollment_id":2,"enrollment_date":"2025-06-01T00:00:00.000Z"}'
                + ',{"enrollment_id":3,"enrollment_date":""}]'
        ));

        Test.startTest();
        KnowBe4Client.EnrollmentSummary summary = KnowBe4Client.summarizeEnrollments(
            3, Datetime.newInstanceGmt(2025, 1, 1, 0, 0, 0)
        );
        Test.stopTest();

        System.assertEquals(3, summary.totalRecords);
        System.assertEquals(1, summary.recordsInScope, 'Only the 2025 row is in scope');
        System.assertEquals(1, summary.pagesFetched, 'A short page ends the scan');
        System.assertEquals(false, summary.hitPageCap);
        System.assertEquals(Datetime.newInstanceGmt(2024, 6, 1, 0, 0, 0), summary.oldest);
        System.assertEquals(Datetime.newInstanceGmt(2025, 6, 1, 0, 0, 0), summary.newest);
    }

    @IsTest
    static void debugFirstPageLogsWithoutThrowing() {
        Test.setMock(HttpCalloutMock.class, new AnyPageStub('[{"enrollment_id":1}]'));

        Test.startTest();
        KnowBe4Client.debugFirstPage();
        Test.stopTest();
    }

    @IsTest
    static void fetchesUsersAtFullPageSize() {
        Test.setMock(HttpCalloutMock.class, new StubResponse(200, '[{"email":"a@b.com"}]'));

        Test.startTest();
        String body = KnowBe4Client.fetchUsers(1);
        Test.stopTest();

        System.assertEquals('[{"email":"a@b.com"}]', body);
    }

    @IsTest
    static void throwsOnNonSuccess() {
        Test.setMock(HttpCalloutMock.class, new StubResponse(401, 'Unauthorized'));

        Test.startTest();
        try {
            KnowBe4Client.fetchEnrollments(1, KnowBe4Client.MAX_PAGE_SIZE);
            System.assert(false, 'A non-200 response should raise');
        } catch (KnowBe4Client.KnowBe4CalloutException e) {
            System.assert(
                e.getMessage().contains('401'),
                'Error should surface the status code, got: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
}