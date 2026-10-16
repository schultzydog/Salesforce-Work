@IsTest(isParallel=false)
private class KnowBe4SyncServiceTest {

    private class KnowBe4Mock implements HttpCalloutMock {
        private String matchedEmail;

        private KnowBe4Mock() {
            this('nobody@example.com');
        }

        private KnowBe4Mock(String matchedEmail) {
            this.matchedEmail = matchedEmail;
        }

        public HttpResponse respond(HttpRequest req) {
            String endpoint = req.getEndpoint();
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);

            if (endpoint.contains('/training/campaigns')) {
                if (endpoint.contains('page=1')) {
                    res.setBody(
                        '['
                            + '{"campaign_id":11,"name":"Old Closed","status":"Closed","start_date":"2022-01-01T00:00:00.000Z","end_date":"2022-01-15T00:00:00.000Z"},'
                            + '{"campaign_id":22,"name":"Old Open","status":"In Progress","start_date":"2024-06-01T00:00:00.000Z","end_date":"2025-06-01T00:00:00.000Z"},'
                            + '{"campaign_id":33,"name":"New Closed","status":"Completed","start_date":"2025-02-01T00:00:00.000Z","end_date":"2025-03-01T00:00:00.000Z"}'
                            + ']'
                    );
                } else {
                    res.setBody('[]');
                }
                return res;
            }

            if (endpoint.contains('/v1/users')) {
                res.setBody(
                    endpoint.contains('page=1')
                        ? '[{"id":1,"email":"' + matchedEmail + '"'
                            + ',"phish_prone_percentage":12.5,"current_risk_score":39.8}]'
                        : '[]'
                );
                return res;
            }

            if (endpoint.contains('campaign_id=22')) {
                res.setBody(enrollmentJson(1001, 'Phish Game', matchedEmail, 'Passed', '1.0'));
                return res;
            }
            if (endpoint.contains('campaign_id=33')) {
                res.setBody(enrollmentJson(1002, 'Password Module', matchedEmail, 'In Progress', '0.75'));
                return res;
            }

            res.setBody('[]');
            return res;
        }
    }

    private static String enrollmentJson(
        Integer enrollmentId,
        String moduleName,
        String email,
        String status,
        String score
    ) {
        return '['
            + '{"enrollment_id":' + enrollmentId
            + ',"module_name":"' + moduleName + '"'
            + ',"user":{"id":1,"email":"' + email + '"}'
            + ',"enrollment_date":"2025-03-01T13:00:00.000Z"'
            + ',"start_date":"2025-03-02T13:00:00.000Z"'
            + ',"completion_date":"2025-03-03T13:00:00.000Z"'
            + ',"status":"' + status + '"'
            + ',"score":' + score
            + '}'
            + ']';
    }

    private static User existingSalesforceUser() {
        return [
            SELECT Id, Email
            FROM User
            WHERE IsActive = true
              AND UserType = 'Standard'
              AND Email != null
            LIMIT 1
        ];
    }

    private static String knowBe4EmailFor(User u) {
        return KnowBe4SyncService.normalizeEmail(u.Email);
    }

    @IsTest
    static void syncsInScopeCampaignsAndMatchesSandboxEmail() {
        User trainee = existingSalesforceUser();
        Test.setMock(HttpCalloutMock.class, new KnowBe4Mock(knowBe4EmailFor(trainee)));

        Test.startTest();
        List<KnowBe4SyncService.CampaignScope> campaigns = KnowBe4SyncService.loadInScopeCampaigns();
        KnowBe4SyncService.SyncResult outcome = KnowBe4SyncService.syncCampaigns(campaigns);
        Test.stopTest();

        Set<Integer> campaignIds = new Set<Integer>();
        for (KnowBe4SyncService.CampaignScope scope : campaigns) {
            campaignIds.add(scope.campaignId);
        }
        System.assertEquals(2, campaignIds.size(), 'Old open and new closed campaigns should be in scope');
        System.assertEquals(false, campaignIds.contains(11), 'Pre-cutoff closed campaign should be skipped');
        System.assertEquals(2, outcome.resultsUpserted, 'Both in-scope enrollments should write');
        System.assertEquals(0, outcome.unmatchedUsers, 'Sandbox .invalid emails should still match');

        KnowBe4_User_Result__c stored = [
            SELECT User__c, Status__c, Score__c, KnowBe4_Module__r.Name
            FROM KnowBe4_User_Result__c
            WHERE External_Id__c = '1001'
        ];
        System.assertEquals(trainee.Id, stored.User__c);
        System.assertEquals('passed', stored.Status__c);
        System.assertEquals('1.0', stored.Score__c);
        System.assertEquals('Phish Game', stored.KnowBe4_Module__r.Name);
    }

    @IsTest
    static void populatesPhishPronePercentageAndRiskScore() {
        User trainee = existingSalesforceUser();
        Test.setMock(HttpCalloutMock.class, new KnowBe4Mock(knowBe4EmailFor(trainee)));

        Test.startTest();
        KnowBe4SyncService.syncCampaigns(
            new List<KnowBe4SyncService.CampaignScope>{ scope(22, Date.newInstance(2025, 6, 1)) }
        );
        Test.stopTest();

        KnowBe4_User_Result__c stored = [
            SELECT Current_PPP__c, Risk_Score__c
            FROM KnowBe4_User_Result__c
            WHERE External_Id__c = '1001'
        ];
        System.assertEquals(12.5, stored.Current_PPP__c);
        System.assertEquals(39.8, stored.Risk_Score__c);
    }

    @IsTest
    static void missingMetricsLeaveStoredScoresAlone() {
        User trainee = existingSalesforceUser();
        KnowBe4_Module__c moduleRecord = new KnowBe4_Module__c(
            Name = 'Phish Game Unchanged',
            Due_Date__c = Date.newInstance(2025, 6, 1)
        );
        insert moduleRecord;
        insert new KnowBe4_User_Result__c(
            External_Id__c = '1001',
            User__c = trainee.Id,
            KnowBe4_Module__c = moduleRecord.Id,
            Enrolled__c = Datetime.newInstanceGmt(2025, 3, 1, 13, 0, 0),
            Started__c = Datetime.newInstanceGmt(2025, 3, 2, 13, 0, 0),
            Completed__c = Datetime.newInstanceGmt(2025, 3, 3, 13, 0, 0),
            Status__c = 'passed',
            Score__c = '1.0',
            Current_PPP__c = 7.25,
            Risk_Score__c = 15.5
        );
        // UnchangedMock answers every endpoint with enrollment JSON, so the
        // users pull comes back with no usable email and no metrics.
        Test.setMock(HttpCalloutMock.class, new UnchangedMock(knowBe4EmailFor(trainee)));

        Test.startTest();
        KnowBe4SyncService.syncCampaigns(
            new List<KnowBe4SyncService.CampaignScope>{ scope(22, Date.newInstance(2025, 6, 1)) }
        );
        Test.stopTest();

        KnowBe4_User_Result__c stored = [
            SELECT Current_PPP__c, Risk_Score__c
            FROM KnowBe4_User_Result__c
            WHERE External_Id__c = '1001'
        ];
        System.assertEquals(7.25, stored.Current_PPP__c, 'A silent users pull must not blank the PPP');
        System.assertEquals(15.5, stored.Risk_Score__c, 'A silent users pull must not blank the risk score');
    }

    @IsTest
    static void skipsUnchangedResultsOnSecondRun() {
        User trainee = existingSalesforceUser();
        KnowBe4_Module__c moduleRecord = new KnowBe4_Module__c(
            Name = 'Phish Game Unchanged',
            Due_Date__c = Date.newInstance(2025, 6, 1)
        );
        insert moduleRecord;
        insert new KnowBe4_User_Result__c(
            External_Id__c = '1001',
            User__c = trainee.Id,
            KnowBe4_Module__c = moduleRecord.Id,
            Enrolled__c = Datetime.newInstanceGmt(2025, 3, 1, 13, 0, 0),
            Started__c = Datetime.newInstanceGmt(2025, 3, 2, 13, 0, 0),
            Completed__c = Datetime.newInstanceGmt(2025, 3, 3, 13, 0, 0),
            Status__c = 'passed',
            Score__c = '1.0'
        );
        Test.setMock(HttpCalloutMock.class, new UnchangedMock(knowBe4EmailFor(trainee)));

        Test.startTest();
        KnowBe4SyncService.SyncResult second = KnowBe4SyncService.syncCampaigns(
            new List<KnowBe4SyncService.CampaignScope>{ scope(22, Date.newInstance(2025, 6, 1)) }
        );
        Test.stopTest();

        System.assertEquals(0, second.resultsUpserted, 'Unchanged enrollments should not be rewritten');
    }

    @IsTest
    static void skipsUnmatchedUsers() {
        Test.setMock(HttpCalloutMock.class, new KnowBe4Mock());

        Test.startTest();
        KnowBe4SyncService.SyncResult outcome = KnowBe4SyncService.syncCampaigns(
            new List<KnowBe4SyncService.CampaignScope>{ scope(22, Date.newInstance(2025, 6, 1)) }
        );
        Test.stopTest();

        System.assertEquals(1, outcome.unmatchedUsers);
        System.assertEquals(0, [SELECT COUNT() FROM KnowBe4_User_Result__c]);
    }

    @IsTest
    static void mapsStatusesAndNormalizesEmail() {
        System.assertEquals('passed', KnowBe4SyncService.mapStatus('Passed'));
        System.assertEquals('in_progress', KnowBe4SyncService.mapStatus('In Progress'));
        System.assertEquals('kb4.sync@example.com', KnowBe4SyncService.normalizeEmail('KB4.Sync@example.com.invalid'));
        System.assertEquals(
            true,
            KnowBe4SyncService.isCampaignInScope(new Map<String, Object>{
                'status' => 'In Progress',
                'start_date' => '2024-01-01T00:00:00.000Z'
            })
        );
    }

    @IsTest
    static void queueableWritesResults() {
        User trainee = existingSalesforceUser();
        Test.setMock(HttpCalloutMock.class, new KnowBe4Mock(knowBe4EmailFor(trainee)));

        Test.startTest();
        System.enqueueJob(new KnowBe4SyncQueueable());
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM KnowBe4_User_Result__c]);
    }

    private class UnchangedMock implements HttpCalloutMock {
        private String matchedEmail;
        private UnchangedMock(String matchedEmail) {
            this.matchedEmail = matchedEmail;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(enrollmentJson(1001, 'Phish Game Unchanged', matchedEmail, 'Passed', '1.0'));
            return res;
        }
    }

    private static KnowBe4SyncService.CampaignScope scope(Integer campaignId, Date dueDate) {
        KnowBe4SyncService.CampaignScope value = new KnowBe4SyncService.CampaignScope();
        value.campaignId = campaignId;
        value.dueDate = dueDate;
        return value;
    }

    @IsTest
    static void scheduleRegistersCronJob() {
        Test.setMock(HttpCalloutMock.class, new KnowBe4Mock());
        Test.startTest();
        String jobId = System.schedule(
            'KnowBe4 Sync Test',
            '0 0 7 3 9 ? 2050',
            new KnowBe4SyncSchedulable()
        );
        Test.stopTest();

        CronTrigger ct = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 7 3 9 ? 2050', ct.CronExpression);
    }
}