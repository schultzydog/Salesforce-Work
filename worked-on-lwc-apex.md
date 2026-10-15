# Salesforce LWC and Apex worked on

Org: EG-Sandbox (eurasiagroup--bolterra). Generated 2026-09-29 20:31.

## Contents

- force-app\main\default\classes\KnowBe4Client.cls
- force-app\main\default\classes\KnowBe4ClientTest.cls
- force-app\main\default\classes\KnowBe4SyncQueueable.cls
- force-app\main\default\classes\KnowBe4SyncSchedulable.cls
- force-app\main\default\classes\KnowBe4SyncService.cls
- force-app\main\default\classes\KnowBe4SyncServiceTest.cls
- force-app\main\default\classes\OutlookEventReviewController.cls
- force-app\main\default\classes\OutlookEventReviewControllerTest.cls
- force-app\main\default\classes\UserFreezeSyncBatch.cls
- force-app\main\default\classes\UserFreezeSyncBatchTest.cls
- force-app\main\default\classes\UserFreezeSyncSchedulable.cls
- force-app\main\default\lwc\egOutlookEventReview\egOutlookEventReview.css
- force-app\main\default\lwc\egOutlookEventReview\egOutlookEventReview.html
- force-app\main\default\lwc\egOutlookEventReview\egOutlookEventReview.js
- force-app\main\default\lwc\egOutlookEventReview\egOutlookEventReview.js-meta.xml
- force-app\main\default\lwc\datatablePractice\datatablePractice.html
- force-app\main\default\lwc\datatablePractice\datatablePractice.js
- force-app\main\default\lwc\datatablePractice\datatablePractice.js-meta.xml

# Apex

## force-app\main\default\classes\KnowBe4Client.cls

```apex
/**
 * Thin HTTP wrapper around the KnowBe4 Reporting API.
 *
 * The region-specific host and the bearer token both live on the KnowBe4 named
 * credential, so neither appears in source.
 */
public with sharing class KnowBe4Client {

    private static final String NAMED_CREDENTIAL = 'callout:knowbe4api';
    public static final Integer MAX_PAGE_SIZE = 500;

    public class KnowBe4CalloutException extends Exception {}

    /** Fetches one page of training enrollments. KnowBe4 pages are 1-indexed. */
    public static String fetchEnrollments(Integer pageNumber, Integer pageSize) {
        return get('/v1/training/enrollments?page=' + pageNumber + '&per_page=' + pageSize);
    }

    /** Campaigns ignore per_page and return 10 rows. Page until an empty list. */
    public static String fetchCampaigns(Integer pageNumber) {
        return get('/v1/training/campaigns?page=' + pageNumber);
    }

    public static String fetchEnrollmentsForCampaign(Integer campaignId, Integer pageNumber) {
        return get(
            '/v1/training/enrollments?campaign_id=' + campaignId
                + '&page=' + pageNumber
                + '&per_page=' + MAX_PAGE_SIZE
        );
    }

    /** GETs an arbitrary KnowBe4 path, e.g. '/v1/training/campaigns'. */
    public static String get(String path) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + path);
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        // Resolved from the named credential's Password field at callout time, so the
        // token is never in source. Requires "Allow Merge Fields in HTTP Header".
        req.setHeader('Authorization', 'Bearer {!$Credential.Password}');
        req.setTimeout(120000);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            throw new KnowBe4CalloutException(
                'KnowBe4 returned HTTP ' + res.getStatusCode() + ': ' + res.getBody()
            );
        }
        return res.getBody();
    }

    public class EnrollmentSummary {
        public Integer totalRecords = 0;
        public Integer recordsInScope = 0;
        public Integer pagesFetched = 0;
        public Boolean hitPageCap = false;
        public Datetime oldest;
        public Datetime newest;
    }

    /**
     * Pages through enrollments counting rows without retaining them, to size the
     * dataset before committing to a sync strategy. Stops at maxPages so a large
     * backlog can't blow the per-transaction callout limits.
     *
     * The endpoint has no date filter, so records older than cutoff still have to be
     * fetched; cutoff only determines what we would keep.
     */
    public static EnrollmentSummary summarizeEnrollments(Integer maxPages, Datetime cutoff) {
        EnrollmentSummary summary = new EnrollmentSummary();

        for (Integer pageNumber = 1; pageNumber <= maxPages; pageNumber++) {
            List<Object> rows =
                (List<Object>) JSON.deserializeUntyped(fetchEnrollments(pageNumber, MAX_PAGE_SIZE));
            summary.pagesFetched++;

            for (Object row : rows) {
                summary.totalRecords++;
                String enrolled = (String) ((Map<String, Object>) row).get('enrollment_date');
                if (String.isBlank(enrolled)) {
                    continue;
                }
                Datetime enrolledAt = (Datetime) JSON.deserialize('"' + enrolled + '"', Datetime.class);
                if (enrolledAt >= cutoff) {
                    summary.recordsInScope++;
                }
                if (summary.oldest == null || enrolledAt < summary.oldest) {
                    summary.oldest = enrolledAt;
                }
                if (summary.newest == null || enrolledAt > summary.newest) {
                    summary.newest = enrolledAt;
                }
            }

            if (rows.size() < MAX_PAGE_SIZE) {
                return summary;
            }
        }

        summary.hitPageCap = true;
        return summary;
    }

    /**
     * Logs a small slice of live data so the field mapping can be written against
     * the real payload rather than guessed from documentation.
     */
    public static void debugFirstPage() {
        String body = fetchEnrollments(1, 5);
        System.debug(LoggingLevel.ERROR, 'KNOWBE4_RESPONSE_START');
        System.debug(LoggingLevel.ERROR, body);
        System.debug(LoggingLevel.ERROR, 'KNOWBE4_RESPONSE_END');
    }
}
```

## force-app\main\default\classes\KnowBe4ClientTest.cls

```apex
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
```

## force-app\main\default\classes\KnowBe4SyncQueueable.cls

```apex
/**
 * Daily KnowBe4 pull. First invocation loads in-scope campaigns, then each job
 * processes CAMPAIGNS_PER_JOB campaigns and chains the remainder so CPU and
 * callout limits stay inside one transaction.
 */
public with sharing class KnowBe4SyncQueueable implements Queueable, Database.AllowsCallouts {

    private final List<KnowBe4SyncService.CampaignScope> remainingCampaigns;

    public KnowBe4SyncQueueable() {
        this(null);
    }

    public KnowBe4SyncQueueable(List<KnowBe4SyncService.CampaignScope> remainingCampaigns) {
        this.remainingCampaigns = remainingCampaigns;
    }

    public void execute(QueueableContext context) {
        List<KnowBe4SyncService.CampaignScope> campaigns = remainingCampaigns;
        if (campaigns == null) {
            campaigns = KnowBe4SyncService.loadInScopeCampaigns();
        }
        if (campaigns.isEmpty()) {
            return;
        }

        List<KnowBe4SyncService.CampaignScope> currentChunk = new List<KnowBe4SyncService.CampaignScope>();
        List<KnowBe4SyncService.CampaignScope> leftover = new List<KnowBe4SyncService.CampaignScope>();
        Integer chunkSize = KnowBe4SyncService.CAMPAIGNS_PER_JOB;
        for (Integer i = 0; i < campaigns.size(); i++) {
            if (i < chunkSize) {
                currentChunk.add(campaigns[i]);
            } else {
                leftover.add(campaigns[i]);
            }
        }

        KnowBe4SyncService.SyncResult outcome = KnowBe4SyncService.syncCampaigns(currentChunk);
        System.debug(
            LoggingLevel.INFO,
            'KnowBe4 sync chunk: campaigns=' + currentChunk.size()
                + ' enrollments=' + outcome.enrollmentsSeen
                + ' resultsWritten=' + outcome.resultsUpserted
                + ' unmatchedUsers=' + outcome.unmatchedUsers
        );
        if (!outcome.unmatchedEmails.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'KnowBe4 unmatched emails: ' + outcome.unmatchedEmails);
        }

        if (!leftover.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new KnowBe4SyncQueueable(leftover));
        }
    }
}
```

## force-app\main\default\classes\KnowBe4SyncSchedulable.cls

```apex
/**
 * Daily entry point for KnowBe4SyncQueueable.
 *
 * Schedule with:
 *   System.schedule('KnowBe4 Sync Daily', '0 0 7 * * ?', new KnowBe4SyncSchedulable());
 */
public with sharing class KnowBe4SyncSchedulable implements Schedulable {

    public void execute(SchedulableContext sc) {
        System.enqueueJob(new KnowBe4SyncQueueable());
    }
}
```

## force-app\main\default\classes\KnowBe4SyncService.cls

```apex
/**
 * Pulls KnowBe4 training campaigns in scope, fetches their enrollments, and
 * upserts Module + User Result records. Only writes rows that actually changed.
 *
 * Campaigns are in scope when they started on/after 2025-01-01, or when they
 * are still open (status is not Closed or Completed). Enrollments older than
 * the cutoff are dropped even if the campaign is in scope.
 */
public without sharing class KnowBe4SyncService {

    public static final Datetime CUTOFF = Datetime.newInstanceGmt(2025, 1, 1, 0, 0, 0);
    public static final Integer CAMPAIGNS_PER_JOB = 15;
    public static final Integer MAX_CAMPAIGN_PAGES = 20;

    private static final Set<String> CLOSED_STATUSES = new Set<String>{
        'closed', 'completed'
    };

    private static final Map<String, String> STATUS_BY_NORMALIZED = new Map<String, String>{
        'passed' => 'passed',
        'completed' => 'passed',
        'past_due' => 'past_due',
        'pastdue' => 'past_due',
        'in_progress' => 'in_progress',
        'inprogress' => 'in_progress',
        'not_started' => 'not_started',
        'notstarted' => 'not_started'
    };

    public class SyncResult {
        public Integer modulesUpserted = 0;
        public Integer resultsUpserted = 0;
        public Integer enrollmentsSeen = 0;
        public Integer unmatchedUsers = 0;
        public List<String> unmatchedEmails = new List<String>();
    }

    public class CampaignScope {
        public Integer campaignId;
        public Date dueDate;
    }

    public static List<CampaignScope> loadInScopeCampaigns() {
        List<CampaignScope> inScope = new List<CampaignScope>();

        for (Integer pageNumber = 1; pageNumber <= MAX_CAMPAIGN_PAGES; pageNumber++) {
            List<Object> rows =
                (List<Object>) JSON.deserializeUntyped(KnowBe4Client.fetchCampaigns(pageNumber));
            if (rows.isEmpty()) {
                break;
            }
            for (Object row : rows) {
                Map<String, Object> campaign = (Map<String, Object>) row;
                if (!isCampaignInScope(campaign)) {
                    continue;
                }
                CampaignScope scope = new CampaignScope();
                scope.campaignId = toInteger(campaign.get('campaign_id'));
                scope.dueDate = dueDateFromCampaign(campaign);
                inScope.add(scope);
            }
        }
        return inScope;
    }

    public static SyncResult syncCampaigns(List<CampaignScope> campaignScopes) {
        SyncResult outcome = new SyncResult();
        if (campaignScopes == null || campaignScopes.isEmpty()) {
            return outcome;
        }

        Map<String, Id> userIdByEmail = loadUserIdsByNormalizedEmail();
        Map<String, KnowBe4_Module__c> modulesByKey = new Map<String, KnowBe4_Module__c>();
        List<EnrollmentDraft> drafts = new List<EnrollmentDraft>();
        Set<String> unmatched = new Set<String>();

        for (CampaignScope scope : campaignScopes) {
            List<Map<String, Object>> enrollments = fetchEnrollmentsForCampaign(scope.campaignId);
            outcome.enrollmentsSeen += enrollments.size();
            Date moduleDueDate = scope.dueDate == null ? CUTOFF.date() : scope.dueDate;

            for (Map<String, Object> enrollment : enrollments) {
            Datetime enrolledAt = parseDatetime(enrollment.get('enrollment_date'));
            if (enrolledAt != null && enrolledAt < CUTOFF) {
                continue;
            }

            String moduleName = moduleKey(enrollment);
            String enrollmentId = enrollmentKey(enrollment.get('enrollment_id'));
            if (String.isBlank(moduleName) || String.isBlank(enrollmentId)) {
                continue;
            }

            Map<String, Object> userNode = (Map<String, Object>) enrollment.get('user');
            String email = userNode == null ? null : (String) userNode.get('email');
            Id userId = userIdByEmail.get(normalizeEmail(email));
            if (userId == null) {
                if (String.isNotBlank(email)) {
                    unmatched.add(email);
                }
                continue;
            }

            String moduleExternalId = moduleExternalId(moduleName, moduleDueDate);
            if (!modulesByKey.containsKey(moduleExternalId)) {
                modulesByKey.put(moduleExternalId, new KnowBe4_Module__c(
                    Name = moduleName.left(80),
                    Module_External_Id__c = moduleExternalId,
                    Due_Date__c = moduleDueDate
                ));
            }

            EnrollmentDraft draft = new EnrollmentDraft();
            draft.moduleName = moduleExternalId;
            draft.result = new KnowBe4_User_Result__c(
                External_Id__c = enrollmentId,
                User__c = userId,
                Enrolled__c = enrolledAt,
                Started__c = parseDatetime(enrollment.get('start_date')),
                Completed__c = parseDatetime(enrollment.get('completion_date')),
                Status__c = mapStatus((String) enrollment.get('status')),
                Score__c = scoreText(enrollment.get('score'))
            );
            drafts.add(draft);
            }
        }

        outcome.unmatchedUsers = unmatched.size();
        outcome.unmatchedEmails.addAll(unmatched);

        Map<String, Id> moduleIdByKey = upsertChangedModules(modulesByKey);
        List<KnowBe4_User_Result__c> proposedResults = new List<KnowBe4_User_Result__c>();
        for (EnrollmentDraft draft : drafts) {
            draft.result.KnowBe4_Module__c = moduleIdByKey.get(draft.moduleName);
            proposedResults.add(draft.result);
        }

        outcome.modulesUpserted = moduleIdByKey.size();
        outcome.resultsUpserted = upsertChangedResults(proposedResults);
        return outcome;
    }

    private class EnrollmentDraft {
        String moduleName;
        KnowBe4_User_Result__c result;
    }

    @TestVisible
    static Boolean isCampaignInScope(Map<String, Object> campaign) {
        String status = String.valueOf(campaign.get('status')).toLowerCase();
        if (!CLOSED_STATUSES.contains(status)) {
            return true;
        }
        Datetime started = parseDatetime(campaign.get('start_date'));
        return started != null && started >= CUTOFF;
    }

    @TestVisible
    static String normalizeEmail(String email) {
        if (String.isBlank(email)) {
            return null;
        }
        String normalized = email.trim().toLowerCase();
        if (normalized.endsWith('.invalid')) {
            normalized = normalized.substring(0, normalized.length() - 8);
        }
        return normalized;
    }

    @TestVisible
    static String mapStatus(String rawStatus) {
        if (String.isBlank(rawStatus)) {
            return null;
        }
        String key = rawStatus.trim().toLowerCase().replace(' ', '_');
        return STATUS_BY_NORMALIZED.get(key);
    }

    private static List<Map<String, Object>> fetchEnrollmentsForCampaign(Integer campaignId) {
        List<Map<String, Object>> enrollments = new List<Map<String, Object>>();
        for (Integer pageNumber = 1; pageNumber <= 10; pageNumber++) {
            List<Object> rows = (List<Object>) JSON.deserializeUntyped(
                KnowBe4Client.fetchEnrollmentsForCampaign(campaignId, pageNumber)
            );
            for (Object row : rows) {
                enrollments.add((Map<String, Object>) row);
            }
            if (rows.size() < KnowBe4Client.MAX_PAGE_SIZE) {
                break;
            }
        }
        return enrollments;
    }

    private static Map<String, Id> loadUserIdsByNormalizedEmail() {
        Map<String, Id> userIdByEmail = new Map<String, Id>();
        for (User u : [
            SELECT Id, Email
            FROM User
            WHERE Email != null
              AND UserType = 'Standard'
        ]) {
            String key = normalizeEmail(u.Email);
            if (key != null && !userIdByEmail.containsKey(key)) {
                userIdByEmail.put(key, u.Id);
            }
        }
        return userIdByEmail;
    }

    private static Map<String, Id> upsertChangedModules(Map<String, KnowBe4_Module__c> proposedByKey) {
        Map<String, Id> idByKey = new Map<String, Id>();
        if (proposedByKey.isEmpty()) {
            return idByKey;
        }

        Map<String, KnowBe4_Module__c> existingByKey = new Map<String, KnowBe4_Module__c>();
        for (KnowBe4_Module__c existing : [
            SELECT Id, Name, Module_External_Id__c, Due_Date__c
            FROM KnowBe4_Module__c
            WHERE Module_External_Id__c IN :proposedByKey.keySet()
        ]) {
            existingByKey.put(existing.Module_External_Id__c.toLowerCase(), existing);
        }

        List<KnowBe4_Module__c> toUpsert = new List<KnowBe4_Module__c>();
        for (String key : proposedByKey.keySet()) {
            KnowBe4_Module__c proposed = proposedByKey.get(key);
            KnowBe4_Module__c existing = existingByKey.get(key.toLowerCase());
            if (existing == null) {
                toUpsert.add(proposed);
                continue;
            }
            idByKey.put(key, existing.Id);
            if (existing.Name != proposed.Name || existing.Due_Date__c != proposed.Due_Date__c) {
                proposed.Id = existing.Id;
                toUpsert.add(proposed);
            }
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert Module_External_Id__c;
        }
        for (KnowBe4_Module__c moduleRecord : proposedByKey.values()) {
            if (moduleRecord.Id != null) {
                idByKey.put(moduleRecord.Module_External_Id__c, moduleRecord.Id);
            }
        }
        return idByKey;
    }

    private static Integer upsertChangedResults(List<KnowBe4_User_Result__c> proposed) {
        if (proposed.isEmpty()) {
            return 0;
        }

        Set<String> keys = new Set<String>();
        for (KnowBe4_User_Result__c result : proposed) {
            keys.add(result.External_Id__c);
        }

        Map<String, KnowBe4_User_Result__c> existingByKey = new Map<String, KnowBe4_User_Result__c>();
        for (KnowBe4_User_Result__c existing : [
            SELECT Id, External_Id__c, User__c, KnowBe4_Module__c, Enrolled__c,
                   Started__c, Completed__c, Status__c, Score__c
            FROM KnowBe4_User_Result__c
            WHERE External_Id__c IN :keys
        ]) {
            existingByKey.put(existing.External_Id__c, existing);
        }

        List<KnowBe4_User_Result__c> toUpsert = new List<KnowBe4_User_Result__c>();
        for (KnowBe4_User_Result__c result : proposed) {
            KnowBe4_User_Result__c existing = existingByKey.get(result.External_Id__c);
            if (existing == null || resultChanged(existing, result)) {
                toUpsert.add(result);
            }
        }

        if (!toUpsert.isEmpty()) {
            Database.upsert(toUpsert, KnowBe4_User_Result__c.External_Id__c, false);
        }
        return toUpsert.size();
    }

    private static Boolean resultChanged(KnowBe4_User_Result__c existing, KnowBe4_User_Result__c proposed) {
        return existing.User__c != proposed.User__c
            || existing.KnowBe4_Module__c != proposed.KnowBe4_Module__c
            || existing.Enrolled__c != proposed.Enrolled__c
            || existing.Started__c != proposed.Started__c
            || existing.Completed__c != proposed.Completed__c
            || existing.Status__c != proposed.Status__c
            || existing.Score__c != proposed.Score__c;
    }

    @TestVisible
    static String moduleExternalId(String moduleName, Date dueDate) {
        Date effectiveDue = dueDate == null ? CUTOFF.date() : dueDate;
        return moduleName.left(80) + String.valueOf(effectiveDue.month()) + String.valueOf(effectiveDue.year());
    }

    @TestVisible
    static Date dueDateFromCampaign(Map<String, Object> campaign) {
        Datetime ended = parseDatetime(campaign.get('end_date'));
        if (ended != null) {
            return ended.date();
        }
        Datetime started = parseDatetime(campaign.get('start_date'));
        return started == null ? CUTOFF.date() : started.date();
    }

    private static String moduleKey(Map<String, Object> enrollment) {
        String name = (String) enrollment.get('module_name');
        return String.isBlank(name) ? null : name.trim();
    }

    private static String enrollmentKey(Object enrollmentId) {
        Integer value = toInteger(enrollmentId);
        return value == null ? null : String.valueOf(value);
    }

    private static String scoreText(Object score) {
        if (score == null) {
            return null;
        }
        return String.valueOf(score).left(5);
    }

    private static Integer toInteger(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Decimal) {
            return ((Decimal) value).intValue();
        }
        if (value instanceof Long) {
            return ((Long) value).intValue();
        }
        return Integer.valueOf(String.valueOf(value));
    }

    @TestVisible
    static Datetime parseDatetime(Object value) {
        if (value == null) {
            return null;
        }
        String raw = String.valueOf(value);
        if (String.isBlank(raw) || raw == 'null') {
            return null;
        }
        return (Datetime) JSON.deserialize('"' + raw + '"', Datetime.class);
    }
}
```

## force-app\main\default\classes\KnowBe4SyncServiceTest.cls

```apex
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
```

## force-app\main\default\classes\OutlookEventReviewController.cls

```apex
/**
 * Backs the Outlook Event Review table: the running user's owned Events,
 * time-entry matching, project suggestions, and working-location updates. Time
 * entry create/edit stays on TimeEntryController.
 */
public with sharing class OutlookEventReviewController {

    public class ActivityRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String subject;
        @AuraEnabled public Datetime activityDate;
        @AuraEnabled public String dayName;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public Decimal hours;
        @AuraEnabled public Date workDate;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String workingLocation;
        @AuraEnabled public Boolean hasTimeEntry;
        @AuraEnabled public Id timeEntryId;
        @AuraEnabled public String timeEntryNotes;
        @AuraEnabled public Id suggestedProjectId;
        @AuraEnabled public String suggestedProjectName;
        @AuraEnabled public Id projectTaskId;
        @AuraEnabled public String projectTaskName;
        @AuraEnabled public Id projectAccountId;
        @AuraEnabled public Boolean projectSearchOnly;
        @AuraEnabled public String timeCategory;
        @AuraEnabled public Boolean internal;
    }

    @AuraEnabled
    public static List<ActivityRow> getMyActivities(Date startDate, Date endDate) {
        Date fromDate = startDate == null ? Date.today().addDays(-180) : startDate;
        Date toDate = endDate == null ? Date.today().addDays(90) : endDate;
        Datetime startBound = Datetime.newInstance(fromDate, Time.newInstance(0, 0, 0, 0));
        Datetime endBound = Datetime.newInstance(toDate, Time.newInstance(23, 59, 59, 0));
        Id ownerId = UserInfo.getUserId();

        List<Event> events = [
            SELECT Id, Subject, StartDateTime, DurationInMinutes, Location,
                   WhatId, What.Name, AccountId, Account.Name,
                   ClientGuid, Type, Activity_Type__c,
                   EG_Time_Entry__c,
                   EG_Time_Entry__r.Notes__c,
                   EG_Time_Entry__r.Hours_Worked__c,
                   EG_Time_Entry__r.EG_Project__c,
                   EG_Time_Entry__r.EG_Project_Task__c,
                   EG_Time_Entry__r.Time_Category__c,
                   EG_Time_Entry__r.Internal__c
            FROM Event
            WHERE OwnerId = :ownerId
            AND IsRecurrence2 = false
            AND StartDateTime >= :startBound
            AND StartDateTime <= :endBound
            AND (ClientGuid != null OR Type = 'Meeting' OR Activity_Type__c = 'Meeting')
            ORDER BY StartDateTime DESC
            LIMIT 500
        ];

        Set<Date> workDates = new Set<Date>();
        Set<Id> whatIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for (Event record : events) {
            if (record.StartDateTime != null) {
                workDates.add(record.StartDateTime.date());
            }
            if (record.WhatId != null) {
                whatIds.add(record.WhatId);
            }
            if (record.AccountId != null) {
                accountIds.add(record.AccountId);
            }
        }

        Map<Date, EG_Time_Card__c> cardsByDate = cardsByDate(ownerId, workDates);
        Map<Date, List<EG_Time_Entry__c>> entriesByDate = entriesByDate(ownerId, workDates);
        Set<Id> prospectAccountIds = new Set<Id>();
        Map<Id, Id> projectBySource = suggestProjects(whatIds, accountIds, prospectAccountIds);

        List<ActivityRow> rows = new List<ActivityRow>();
        for (Event record : events) {
            ActivityRow row = new ActivityRow();
            row.id = record.Id;
            row.subject = record.Subject;
            row.activityDate = record.StartDateTime;
            row.dayName = record.StartDateTime == null
                ? null
                : record.StartDateTime.format('EEEE');
            row.hours = record.DurationInMinutes == null
                ? null
                : Decimal.valueOf(record.DurationInMinutes) / 60;
            row.workDate = record.StartDateTime == null ? null : record.StartDateTime.date();
            row.recordUrl = '/' + record.Id;
            row.accountName = record.Account == null ? null : record.Account.Name;
            Id linkedAccountId = record.AccountId;
            if (String.isBlank(row.accountName) && record.WhatId != null
                && record.WhatId.getSObjectType() == Account.SObjectType) {
                row.accountName = record.What.Name;
                linkedAccountId = record.WhatId;
            }
            row.accountUrl = linkedAccountId == null ? null : '/' + linkedAccountId;
            row.suggestedProjectId = projectBySource.get(record.WhatId);
            if (row.suggestedProjectId == null) {
                row.suggestedProjectId = projectBySource.get(record.AccountId);
            }
            row.internal = false;
            Id relatedAccountId = record.AccountId;
            if (relatedAccountId == null && record.WhatId != null
                && record.WhatId.getSObjectType() == Account.SObjectType) {
                relatedAccountId = record.WhatId;
            }
            if (prospectAccountIds.contains(relatedAccountId)) {
                row.projectAccountId = relatedAccountId;
            }
            row.projectSearchOnly =
                row.suggestedProjectId == null && row.projectAccountId != null;

            EG_Time_Card__c card = cardsByDate.get(row.workDate);
            row.workingLocation = locationFor(card, row.workDate);

            EG_Time_Entry__c matched = record.EG_Time_Entry__r;
            if (matched == null) {
                matched = matchEntry(
                    record,
                    entriesByDate.get(row.workDate),
                    row.suggestedProjectId
                );
            }
            row.hasTimeEntry = matched != null;
            if (matched != null) {
                row.timeEntryId = matched.Id;
                row.timeEntryNotes = matched.Notes__c;
                if (matched.Hours_Worked__c != null) {
                    row.hours = matched.Hours_Worked__c;
                }
                if (matched.EG_Project__c != null) {
                    row.suggestedProjectId = matched.EG_Project__c;
                }
                row.projectTaskId = matched.EG_Project_Task__c;
                row.timeCategory = matched.Time_Category__c;
                row.internal = matched.Internal__c == true;
            }
            rows.add(row);
        }
        applyLookupNames(rows);
        return rows;
    }

    private static void applyLookupNames(List<ActivityRow> rows) {
        Set<Id> projectIds = new Set<Id>();
        Set<Id> taskIds = new Set<Id>();
        for (ActivityRow row : rows) {
            if (row.suggestedProjectId != null) {
                projectIds.add(row.suggestedProjectId);
            }
            if (row.projectTaskId != null) {
                taskIds.add(row.projectTaskId);
            }
        }
        Map<Id, EG_Project__c> projects = projectIds.isEmpty()
            ? new Map<Id, EG_Project__c>()
            : new Map<Id, EG_Project__c>([SELECT Id, Name FROM EG_Project__c WHERE Id IN :projectIds]);
        Map<Id, EG_Project_Task__c> tasks = taskIds.isEmpty()
            ? new Map<Id, EG_Project_Task__c>()
            : new Map<Id, EG_Project_Task__c>([SELECT Id, Name FROM EG_Project_Task__c WHERE Id IN :taskIds]);
        for (ActivityRow row : rows) {
            EG_Project__c project = projects.get(row.suggestedProjectId);
            row.suggestedProjectName = project == null ? null : project.Name;
            EG_Project_Task__c task = tasks.get(row.projectTaskId);
            row.projectTaskName = task == null ? null : task.Name;
        }
    }

    @AuraEnabled
    public static void deleteEvent(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('A record is required.');
        }
        String prefix = String.valueOf(recordId).substring(0, 3);
        if (prefix != Event.SObjectType.getDescribe().getKeyPrefix()) {
            throw new AuraHandledException('Only events can be deleted.');
        }
        delete new Event(Id = recordId);
    }

    @AuraEnabled
    public static void linkTimeEntry(Id eventId, Id timeEntryId) {
        if (eventId == null || timeEntryId == null) {
            return;
        }
        update new Event(Id = eventId, EG_Time_Entry__c = timeEntryId);
    }

    @AuraEnabled
    public static void setWorkingLocation(Date workDate, String locationValue) {
        if (workDate == null) {
            throw new AuraHandledException('A date is required.');
        }
        String fieldName = locationFieldFor(workDate);
        if (fieldName == null) {
            return;
        }
        List<EG_Time_Card__c> cards = [
            SELECT Id
            FROM EG_Time_Card__c
            WHERE OwnerId = :UserInfo.getUserId()
            AND Start_Date__c <= :workDate
            AND End_Date__c >= :workDate
            ORDER BY Start_Date__c DESC
            LIMIT 1
        ];
        if (cards.isEmpty()) {
            throw new AuraHandledException(
                'No time card was found for the week of ' +
                String.valueOf(workDate) +
                '. Create your weekly time card before logging a location.'
            );
        }
        EG_Time_Card__c updateCard = new EG_Time_Card__c(Id = cards[0].Id);
        updateCard.put(fieldName, locationValue);
        update updateCard;
    }

    private static Map<Date, EG_Time_Card__c> cardsByDate(Id ownerId, Set<Date> workDates) {
        Map<Date, EG_Time_Card__c> byDate = new Map<Date, EG_Time_Card__c>();
        if (workDates.isEmpty()) {
            return byDate;
        }
        Date minDate;
        Date maxDate;
        for (Date workDate : workDates) {
            minDate = minDate == null || workDate < minDate ? workDate : minDate;
            maxDate = maxDate == null || workDate > maxDate ? workDate : maxDate;
        }
        List<EG_Time_Card__c> cards = [
            SELECT Id, Start_Date__c, End_Date__c,
                   Location_Monday__c, Location_Tuesday__c, Location_Wednesday__c,
                   Location_Thursday__c, Location_Friday__c
            FROM EG_Time_Card__c
            WHERE OwnerId = :ownerId
            AND Start_Date__c <= :maxDate
            AND End_Date__c >= :minDate
        ];
        for (Date workDate : workDates) {
            for (EG_Time_Card__c card : cards) {
                if (card.Start_Date__c <= workDate && card.End_Date__c >= workDate) {
                    byDate.put(workDate, card);
                    break;
                }
            }
        }
        return byDate;
    }

    private static Map<Date, List<EG_Time_Entry__c>> entriesByDate(Id ownerId, Set<Date> workDates) {
        Map<Date, List<EG_Time_Entry__c>> byDate = new Map<Date, List<EG_Time_Entry__c>>();
        if (workDates.isEmpty()) {
            return byDate;
        }
        for (EG_Time_Entry__c entry : [
            SELECT Id, Date__c, Notes__c, EG_Project__c, EG_Project_Task__c,
                   Hours_Worked__c, Time_Category__c, Internal__c
            FROM EG_Time_Entry__c
            WHERE EG_Time_Card__r.OwnerId = :ownerId
            AND Date__c IN :workDates
        ]) {
            if (!byDate.containsKey(entry.Date__c)) {
                byDate.put(entry.Date__c, new List<EG_Time_Entry__c>());
            }
            byDate.get(entry.Date__c).add(entry);
        }
        return byDate;
    }

    private static EG_Time_Entry__c matchEntry(
        Event record,
        List<EG_Time_Entry__c> sameDay,
        Id suggestedProjectId
    ) {
        if (sameDay == null || sameDay.isEmpty()) {
            return null;
        }
        for (EG_Time_Entry__c entry : sameDay) {
            if (record.WhatId != null && entry.EG_Project__c == record.WhatId) {
                return entry;
            }
            if (suggestedProjectId != null && entry.EG_Project__c == suggestedProjectId) {
                return entry;
            }
        }
        for (EG_Time_Entry__c entry : sameDay) {
            if (String.isNotBlank(record.Subject) && entry.Notes__c == record.Subject) {
                return entry;
            }
        }
        return null;
    }

    private static Map<Id, Id> suggestProjects(
        Set<Id> whatIds,
        Set<Id> accountIds,
        Set<Id> prospectAccountIds
    ) {
        Map<Id, Id> projectBySource = new Map<Id, Id>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> relatedAccountIds = new Set<Id>(accountIds);

        for (Id whatId : whatIds) {
            Schema.SObjectType type = whatId.getSObjectType();
            if (type == EG_Project__c.SObjectType) {
                projectIds.add(whatId);
                projectBySource.put(whatId, whatId);
            } else if (type == Opportunity.SObjectType) {
                opportunityIds.add(whatId);
            } else if (type == Account.SObjectType) {
                relatedAccountIds.add(whatId);
            }
        }

        if (!opportunityIds.isEmpty()) {
            for (EG_Project__c project : [
                SELECT Id, Linked_Opportunity__c
                FROM EG_Project__c
                WHERE Linked_Opportunity__c IN :opportunityIds
            ]) {
                if (!projectBySource.containsKey(project.Linked_Opportunity__c)) {
                    projectBySource.put(project.Linked_Opportunity__c, project.Id);
                }
            }
        }

        if (!relatedAccountIds.isEmpty()) {
            for (Account account : [
                SELECT Id, Gloma_Client_Type__c
                FROM Account
                WHERE Id IN :relatedAccountIds
            ]) {
                if (account.Gloma_Client_Type__c == 'Prospect') {
                    prospectAccountIds.add(account.Id);
                }
            }
        }
        if (prospectAccountIds.isEmpty()) {
            return projectBySource;
        }

        Map<Id, List<Id>> openOppsByAccount = new Map<Id, List<Id>>();
        Set<Id> openOppIds = new Set<Id>();
        for (Opportunity opp : [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE AccountId IN :prospectAccountIds
            AND IsClosed = false
        ]) {
            if (!openOppsByAccount.containsKey(opp.AccountId)) {
                openOppsByAccount.put(opp.AccountId, new List<Id>());
            }
            openOppsByAccount.get(opp.AccountId).add(opp.Id);
            openOppIds.add(opp.Id);
        }
        if (openOppIds.isEmpty()) {
            return projectBySource;
        }

        Map<Id, Id> projectByOpp = new Map<Id, Id>();
        for (EG_Project__c project : [
            SELECT Id, Linked_Opportunity__c
            FROM EG_Project__c
            WHERE Linked_Opportunity__c IN :openOppIds
        ]) {
            if (!projectByOpp.containsKey(project.Linked_Opportunity__c)) {
                projectByOpp.put(project.Linked_Opportunity__c, project.Id);
            }
        }

        for (Id accountId : prospectAccountIds) {
            List<Id> opps = openOppsByAccount.get(accountId);
            if (opps == null || opps.size() != 1) {
                continue;
            }
            Id projectId = projectByOpp.get(opps[0]);
            if (projectId != null && !projectBySource.containsKey(accountId)) {
                projectBySource.put(accountId, projectId);
            }
        }
        return projectBySource;
    }

    private static String locationFor(EG_Time_Card__c card, Date workDate) {
        if (card == null || workDate == null) {
            return null;
        }
        String fieldName = locationFieldFor(workDate);
        if (fieldName == null) {
            return null;
        }
        return (String) card.get(fieldName);
    }

    private static String locationFieldFor(Date workDate) {
        String dayName = Datetime.newInstance(workDate, Time.newInstance(12, 0, 0, 0)).format('EEEE');
        if (dayName == 'Monday') {
            return 'Location_Monday__c';
        }
        if (dayName == 'Tuesday') {
            return 'Location_Tuesday__c';
        }
        if (dayName == 'Wednesday') {
            return 'Location_Wednesday__c';
        }
        if (dayName == 'Thursday') {
            return 'Location_Thursday__c';
        }
        if (dayName == 'Friday') {
            return 'Location_Friday__c';
        }
        return null;
    }
}
```

## force-app\main\default\classes\OutlookEventReviewControllerTest.cls

```apex
@IsTest
private class OutlookEventReviewControllerTest {

    @IsTest
    static void returnsOwnedEventsWithDayName() {
        Event meeting = new Event(
            Subject = 'My Activity Table Event',
            Type = 'Meeting',
            Activity_Type__c = 'Meeting',
            StartDateTime = Datetime.now().addDays(-1),
            EndDateTime = Datetime.now().addDays(-1).addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(null, null);
        Test.stopTest();

        OutlookEventReviewController.ActivityRow found = findRow(rows, meeting.Id);
        System.assertNotEquals(null, found, 'Owner should see their event');
        System.assertEquals(false, found.hasTimeEntry);
        System.assertEquals(true, String.isNotBlank(found.dayName));
    }

    @IsTest
    static void deletesEvent() {
        Event meeting = new Event(
            Subject = 'Flag Me',
            Type = 'Meeting',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;

        Test.startTest();
        OutlookEventReviewController.deleteEvent(meeting.Id);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Event WHERE Id = :meeting.Id]);
    }

    @IsTest
    static void suggestsProjectWhenEventIsRelatedToProject() {
        EG_Project__c project = new EG_Project__c(Name = 'Activity Table Project');
        insert project;

        Event meeting = new Event(
            Subject = 'Project meeting',
            Type = 'Meeting',
            StartDateTime = Datetime.now(),
            EndDateTime = Datetime.now().addHours(1),
            WhatId = project.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(null, null);
        Test.stopTest();

        OutlookEventReviewController.ActivityRow found = findRow(rows, meeting.Id);
        System.assertEquals(project.Id, found.suggestedProjectId);
        System.assertEquals('Activity Table Project', found.suggestedProjectName);
    }

    @IsTest
    static void matchesTimeEntryByNotesAndSavesLocation() {
        Date weekStart = Date.today().toStartOfWeek();
        Date weekEnd = weekStart.addDays(6);
        EG_Time_Card__c card = TestDataFactory.newTimeCard(weekStart, weekEnd);
        Date workDate = Date.today();
        insert new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = workDate,
            Hours_Worked__c = 1,
            Notes__c = 'Notes match event',
            ExternalID__c = String.valueOf(card.Id) + ':null:null:' + String.valueOf(workDate)
        );

        Datetime startAt = Datetime.newInstance(workDate, Time.newInstance(10, 0, 0, 0));
        Event meeting = new Event(
            Subject = 'Notes match event',
            Type = 'Meeting',
            StartDateTime = startAt,
            EndDateTime = startAt.addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(null, null);
        OutlookEventReviewController.setWorkingLocation(workDate, firstLocationValue());
        // Saturday has no location field, so the call is a no-op.
        OutlookEventReviewController.setWorkingLocation(Date.newInstance(2026, 1, 3), 'WFH');
        Test.stopTest();

        OutlookEventReviewController.ActivityRow found = findRow(rows, meeting.Id);
        System.assertEquals(true, found.hasTimeEntry);
        System.assertEquals('Notes match event', found.timeEntryNotes);
    }

    @IsTest
    static void suggestsProjectFromRelatedOpportunity() {
        Opportunity opp = TestDataFactory.newOpportunity();
        EG_Project__c project = TestDataFactory.newProject(opp.Id);

        Datetime startAt = Datetime.now();
        Event meeting = new Event(
            Subject = 'Opp meeting',
            Type = 'Meeting',
            StartDateTime = startAt,
            EndDateTime = startAt.addHours(1),
            WhatId = opp.Id,
            OwnerId = UserInfo.getUserId()
        );
        insert meeting;

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(null, null);
        Test.stopTest();

        OutlookEventReviewController.ActivityRow found = findRow(rows, meeting.Id);
        System.assertEquals(project.Id, found.suggestedProjectId);
    }

    @IsTest
    static void dateRangeExcludesOldEventsAndLinksTimeEntry() {
        Datetime oldStart = Datetime.now().addDays(-200);
        insert new Event(
            Subject = 'Too old',
            Type = 'Meeting',
            StartDateTime = oldStart,
            EndDateTime = oldStart.addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        Datetime recentStart = Datetime.now();
        Event recent = new Event(
            Subject = 'Recent meeting',
            Type = 'Meeting',
            StartDateTime = recentStart,
            EndDateTime = recentStart.addHours(1),
            OwnerId = UserInfo.getUserId()
        );
        insert recent;
        Date weekStart = Date.today().toStartOfWeek();
        EG_Time_Card__c card = TestDataFactory.newTimeCard(weekStart, weekStart.addDays(6));
        EG_Time_Entry__c entry = new EG_Time_Entry__c(
            EG_Time_Card__c = card.Id,
            Date__c = Date.today(),
            Hours_Worked__c = 1,
            ExternalID__c = String.valueOf(card.Id) + ':link:' + String.valueOf(Date.today())
        );
        insert entry;

        Test.startTest();
        List<OutlookEventReviewController.ActivityRow> rows =
            OutlookEventReviewController.getMyActivities(Date.today().addDays(-7), Date.today().addDays(1));
        OutlookEventReviewController.linkTimeEntry(recent.Id, entry.Id);
        Test.stopTest();

        System.assertEquals(null, findRow(rows, [SELECT Id FROM Event WHERE Subject = 'Too old' LIMIT 1].Id));
        System.assertNotEquals(null, findRow(rows, recent.Id));
        Event stored = [SELECT EG_Time_Entry__c FROM Event WHERE Id = :recent.Id];
        System.assertEquals(entry.Id, stored.EG_Time_Entry__c);
    }

    @IsTest
    static void locationAndFlagRejectBadInput() {
        Test.startTest();
        try {
            OutlookEventReviewController.setWorkingLocation(null, 'WFH');
            System.assert(false, 'null date should fail');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
        try {
            OutlookEventReviewController.setWorkingLocation(Date.newInstance(2010, 1, 4), 'WFH');
            System.assert(false, 'missing time card should fail');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
        try {
            OutlookEventReviewController.deleteEvent(null);
            System.assert(false, 'null record should fail');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
        try {
            OutlookEventReviewController.deleteEvent(UserInfo.getUserId());
            System.assert(false, 'non-event should fail');
        } catch (AuraHandledException expected) {
            System.assert(true);
        }
        Test.stopTest();
    }

    private static String firstLocationValue() {
        for (Schema.PicklistEntry entry : EG_Time_Card__c.Location_Monday__c.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }

    private static OutlookEventReviewController.ActivityRow findRow(
        List<OutlookEventReviewController.ActivityRow> rows,
        Id recordId
    ) {
        for (OutlookEventReviewController.ActivityRow row : rows) {
            if (row.id == recordId) {
                return row;
            }
        }
        return null;
    }
}
```

## force-app\main\default\classes\UserFreezeSyncBatch.cls

```apex
/**
 * Keeps User.Is_Frozen__c in step with UserLogin.IsFrozen in both directions:
 * freezing sets the flag, unfreezing clears it.
 *
 * UserLogin does not support triggers or record-triggered flows, so freeze state is
 * polled on a schedule instead of reacted to in real time.
 */
public with sharing class UserFreezeSyncBatch implements Database.Batchable<SObject>, Database.Stateful {

    /**
     * Users whose freeze status changed during this run, mapped to the status they
     * moved to. True means they became frozen, false means they became unfrozen.
     */
    private Map<Id, Boolean> freezeStatusChanges = new Map<Id, Boolean>();

    private final Set<Id> scopedUserIds;

    public UserFreezeSyncBatch() {
        this(null);
    }

    /** Restricts the run to specific users. Used by tests and ad-hoc re-syncs. */
    public UserFreezeSyncBatch(Set<Id> scopedUserIds) {
        this.scopedUserIds = scopedUserIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (scopedUserIds != null) {
            Set<Id> targetUserIds = scopedUserIds;
            return Database.getQueryLocator([
                SELECT Id, UserId, IsFrozen
                FROM UserLogin
                WHERE UserId IN :targetUserIds
            ]);
        }
        return Database.getQueryLocator([
            SELECT Id, UserId, IsFrozen
            FROM UserLogin
            WHERE UserId IN (
                SELECT Id FROM User WHERE IsActive = true OR Is_Frozen__c = true
            )
        ]);
    }

    public void execute(Database.BatchableContext bc, List<UserLogin> scope) {
        Map<Id, Boolean> loginFrozenByUserId = new Map<Id, Boolean>();
        for (UserLogin login : scope) {
            if (login.UserId != null) {
                loginFrozenByUserId.put(login.UserId, login.IsFrozen);
            }
        }
        if (loginFrozenByUserId.isEmpty()) {
            return;
        }

        List<User> usersWithChangedStatus = new List<User>();
        for (User u : [
            SELECT Id, Is_Frozen__c
            FROM User
            WHERE Id IN :loginFrozenByUserId.keySet()
        ]) {
            Boolean isFrozenOnLogin = loginFrozenByUserId.get(u.Id) == true;
            Boolean isFrozenOnUser = u.Is_Frozen__c == true;

            if (isFrozenOnLogin == isFrozenOnUser) {
                continue;
            }

            freezeStatusChanges.put(u.Id, isFrozenOnLogin);
            usersWithChangedStatus.add(new User(Id = u.Id, Is_Frozen__c = isFrozenOnLogin));
        }

        if (!usersWithChangedStatus.isEmpty()) {
            update usersWithChangedStatus;
        }
    }

    public void finish(Database.BatchableContext bc) {
        Set<Id> becameFrozen = new Set<Id>();
        Set<Id> becameUnfrozen = new Set<Id>();

        for (Id userId : freezeStatusChanges.keySet()) {
            if (freezeStatusChanges.get(userId)) {
                becameFrozen.add(userId);
            } else {
                becameUnfrozen.add(userId);
            }
        }

        // Alerting hooks off these sets once notification requirements are settled.
        System.debug('Became frozen: ' + becameFrozen);
        System.debug('Became unfrozen: ' + becameUnfrozen);
    }
}
```

## force-app\main\default\classes\UserFreezeSyncBatchTest.cls

```apex
@IsTest
private class UserFreezeSyncBatchTest {

    private static User buildTestUser(String aliasSuffix) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String unique = String.valueOf(Crypto.getRandomLong()).replace('-', '');
        return new User(
            FirstName = 'Freeze',
            LastName = 'SyncTest',
            Alias = 'frz' + aliasSuffix,
            Email = 'freeze.synctest@example.com',
            Username = 'freeze.synctest.' + unique + '@example.com.invalid',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
    }

    private static User insertTestUser(String aliasSuffix, Boolean preSetFlag) {
        User target = buildTestUser(aliasSuffix);
        target.Is_Frozen__c = preSetFlag;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert target;
        }
        return target;
    }

    @IsTest
    static void mirrorsFrozenStateOntoUser() {
        User target = insertTestUser('a', false);

        UserLogin login = [SELECT Id FROM UserLogin WHERE UserId = :target.Id LIMIT 1];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            update new UserLogin(Id = login.Id, IsFrozen = true);
        }

        Test.startTest();
        Database.executeBatch(new UserFreezeSyncBatch(new Set<Id>{ target.Id }), 200);
        Test.stopTest();

        User synced = [SELECT Is_Frozen__c FROM User WHERE Id = :target.Id];
        System.assertEquals(true, synced.Is_Frozen__c, 'Frozen login should set the User flag');
    }

    @IsTest
    static void clearsFlagWhenUnfrozen() {
        User target = insertTestUser('b', true);

        Test.startTest();
        Database.executeBatch(new UserFreezeSyncBatch(new Set<Id>{ target.Id }), 200);
        Test.stopTest();

        User synced = [SELECT Is_Frozen__c FROM User WHERE Id = :target.Id];
        System.assertEquals(false, synced.Is_Frozen__c, 'Unfrozen login should clear the User flag');
    }

    @IsTest
    static void schedulableRunsTheBatch() {
        User target = insertTestUser('c', true);

        Test.startTest();
        new UserFreezeSyncSchedulable(new Set<Id>{ target.Id }).execute(null);
        Test.stopTest();

        User synced = [SELECT Is_Frozen__c FROM User WHERE Id = :target.Id];
        System.assertEquals(false, synced.Is_Frozen__c, 'Scheduled run should sync the User flag');
    }

    @IsTest
    static void scheduleRegistersCronJob() {
        Test.startTest();
        String jobId = System.schedule(
            'User Freeze Sync Test',
            '0 0 6 3 9 ? 2050',
            new UserFreezeSyncSchedulable(new Set<Id>())
        );
        Test.stopTest();

        CronTrigger ct = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 6 3 9 ? 2050', ct.CronExpression, 'Job should register with the given cron');
    }

    @IsTest
    static void defaultConstructorTargetsAllLogins() {
        System.assertNotEquals(null, new UserFreezeSyncBatch(), 'No-arg constructor should build an unfiltered batch');
        System.assertNotEquals(null, new UserFreezeSyncSchedulable(), 'No-arg schedulable should build');
    }
}
```

## force-app\main\default\classes\UserFreezeSyncSchedulable.cls

```apex
/**
 * Daily entry point for UserFreezeSyncBatch.
 *
 * Schedule with:
 *   System.schedule('User Freeze Sync Daily', '0 0 6 * * ?', new UserFreezeSyncSchedulable());
 */
public with sharing class UserFreezeSyncSchedulable implements Schedulable {

    private final Set<Id> userIdFilter;

    public UserFreezeSyncSchedulable() {
        this(null);
    }

    /** Restricts the run to specific users. Used by tests and ad-hoc re-syncs. */
    public UserFreezeSyncSchedulable(Set<Id> userIdFilter) {
        this.userIdFilter = userIdFilter;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new UserFreezeSyncBatch(userIdFilter), 200);
    }
}
```

# Lightning Web Components

## force-app\main\default\lwc\egOutlookEventReview\egOutlookEventReview.css

```css
:host {
    display: block;
    background: #ffffff;
    /* Fills the tab so the app page background image stays covered. */
    min-height: calc(100vh - 7rem);
}

.filters {
    padding: 0.75rem 1rem 0.25rem;
}

.table-wrap {
    position: relative;
    min-height: 12rem;
    padding: 0 1rem 1rem;
}

table.time-table {
    width: 100%;
    border: 1px solid #bbbbbb;
    border-collapse: collapse;
}

table.time-table th,
table.time-table td {
    border: 1px solid #bbbbbb;
    padding: 0.25rem 0.4rem;
    vertical-align: middle;
}

table.time-table th {
    background: #f5f5f5;
    font-weight: 700;
    text-align: left;
    white-space: nowrap;
}

table.time-table th.sortable {
    cursor: pointer;
}

.sort-indicator {
    font-weight: 400;
    color: #706e6b;
}

.day-sub {
    color: #706e6b;
    font-size: 0.75rem;
}

.col-date {
    width: 11rem;
    white-space: nowrap;
}

.col-subject {
    min-width: 11rem;
}

.col-account {
    width: 10rem;
}

.col-project,
.col-task {
    width: 15%;
    min-width: 10rem;
}

.col-hours {
    width: 5.5rem;
}

.col-location {
    width: 11rem;
}

.col-delete {
    width: 3rem;
    text-align: center;
}
```

## force-app\main\default\lwc\egOutlookEventReview\egOutlookEventReview.html

```html
<template>
    <lightning-card title="Outlook Event Review">
        <div class="filters">
            <div class="slds-grid slds-gutters slds-grid_vertical-align-end">
                <!--
                <div class="slds-col slds-grow-none">
                    <lightning-input
                        type="date"
                        label="From"
                        value={fromDate}
                        onchange={handleFromDateChange}
                    ></lightning-input>
                </div>
                <div class="slds-col slds-grow-none">
                    <lightning-input
                        type="date"
                        label="To"
                        value={toDate}
                        onchange={handleToDateChange}
                    ></lightning-input>
                </div>
                -->
                <div class="slds-col slds-grow-none">
                    <lightning-combobox
                        label="Time entry"
                        value={timeEntryFilter}
                        options={timeEntryFilterOptions}
                        onchange={handleTimeEntryFilterChange}
                    ></lightning-combobox>
                </div>
            </div>
        </div>

        <div class="table-wrap">
            <table class="time-table">
                <thead>
                    <tr>
                        <th class="col-date sortable" onclick={handleSortDate}>
                            Start Date/Time
                            <span class="sort-indicator">{dateSortMark}</span>
                        </th>
                        <th class="col-subject sortable" onclick={handleSortSubject}>
                            Subject
                            <span class="sort-indicator">{subjectSortMark}</span>
                        </th>
                        <th class="col-account">Account</th>
                        <th class="col-project">Project</th>
                        <th class="col-task">Task</th>
                        <th class="col-hours">Hours</th>
                        <th class="col-location">Location</th>
                        <th class="col-delete"></th>
                    </tr>
                </thead>
                <tbody>
                    <template for:each={visibleRows} for:item="row">
                        <tr key={row.rowKey}>
                            <td class="col-date">
                                <div>{row.displayDate}</div>
                                <div class="day-sub">{row.dayName}</div>
                            </td>
                            <td class="col-subject">
                                <a href={row.recordUrl} target="_blank">{row.subject}</a>
                            </td>
                            <td class="col-account">
                                <template lwc:if={row.accountUrl}>
                                    <a href={row.accountUrl} target="_blank">{row.accountName}</a>
                                </template>
                                <template lwc:else>{row.accountName}</template>
                            </td>
                            <td class="col-project">
                                <c-eg-custom-lookup
                                    type="EG_Project__c"
                                    value={row.suggestedProjectId}
                                    selection={row.suggestedProjectName}
                                    icon-name="standard:work_step"
                                    placeholder="Search projects"
                                    data-row-id={row.id}
                                    onselect={handleProjectChange}
                                ></c-eg-custom-lookup>
                            </td>
                            <td class="col-task">
                                <c-eg-custom-lookup
                                    type="EG_Project_Task__c"
                                    value={row.projectTaskId}
                                    selection={row.projectTaskName}
                                    icon-name="standard:work_order_item"
                                    placeholder="Select task"
                                    disabled={row.noProject}
                                    filter-field="EG_Project__c"
                                    filter-value={row.suggestedProjectId}
                                    data-row-id={row.id}
                                    onselect={handleTaskChange}
                                ></c-eg-custom-lookup>
                            </td>
                            <td class="col-hours">
                                <lightning-input
                                    type="number"
                                    label="Hours"
                                    variant="label-hidden"
                                    value={row.hours}
                                    step="0.25"
                                    min="0"
                                    formatter="decimal"
                                    data-row-id={row.id}
                                    data-field="hours"
                                    onchange={handleInlineChange}
                                ></lightning-input>
                            </td>
                            <td class="col-location">
                                <template lwc:if={row.showLocation}>
                                    <lightning-combobox
                                        label="Location"
                                        variant="label-hidden"
                                        value={row.workingLocation}
                                        options={locationOptions}
                                        data-row-id={row.id}
                                        data-field="workingLocation"
                                        onchange={handleInlineChange}
                                    ></lightning-combobox>
                                </template>
                            </td>
                            <td class="col-delete">
                                <lightning-button-icon
                                    icon-name="utility:delete"
                                    alternative-text="Delete"
                                    title="Delete"
                                    variant="bare"
                                    data-row-id={row.id}
                                    onclick={handleDelete}
                                ></lightning-button-icon>
                            </td>
                        </tr>
                    </template>
                </tbody>
            </table>
            <template lwc:if={isEmpty}>
                <p class="slds-text-body_small slds-text-align_center slds-var-p-around_medium">
                    No events found.
                </p>
            </template>
            <template lwc:if={isLoading}>
                <lightning-spinner alternative-text="Loading" size="small"></lightning-spinner>
            </template>
        </div>
    </lightning-card>
</template>
```

## force-app\main\default\lwc\egOutlookEventReview\egOutlookEventReview.js

```javascript
import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import LightningConfirm from 'lightning/confirm';
import NO_FLEXIPAGE_HEADER from '@salesforce/resourceUrl/EGNoFlexipageHeader';
import LOCATION_MONDAY from '@salesforce/schema/EG_Time_Card__c.Location_Monday__c';
import getMyActivities from '@salesforce/apex/OutlookEventReviewController.getMyActivities';
import setWorkingLocation from '@salesforce/apex/OutlookEventReviewController.setWorkingLocation';
import linkTimeEntry from '@salesforce/apex/OutlookEventReviewController.linkTimeEntry';
import deleteEvent from '@salesforce/apex/OutlookEventReviewController.deleteEvent';
import createTimeEntry from '@salesforce/apex/TimeEntryController.createTimeEntry';

const DAY_MS = 24 * 60 * 60 * 1000;

export default class EgOutlookEventReview extends LightningElement {
    allRows = [];
    timeEntryFilter = 'all';
    sortField = 'activityDate';
    sortDirection = 'desc';
    isLoading = false;
    fromDate;
    toDate;
    locationOptions = [{ label: 'None', value: '' }];
    savesInFlight = {};

    timeEntryFilterOptions = [
        { label: 'With or without', value: 'all' },
        { label: 'With time entry', value: 'with' },
        { label: 'Without time entry', value: 'without' }
    ];

    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: LOCATION_MONDAY
    })
    wiredLocations({ data }) {
        if (data) {
            this.locationOptions = [{ label: 'None', value: '' }].concat(data.values);
        }
    }

    connectedCallback() {
        // Hides the standard app-page header; only reachable from a global stylesheet.
        loadStyle(this, NO_FLEXIPAGE_HEADER);
        this.fromDate = this.toIsoDate(new Date(Date.now() - 180 * DAY_MS));
        this.toDate = this.toIsoDate(new Date(Date.now() + 90 * DAY_MS));
        this.loadRows();
    }

    get visibleRows() {
        let rows = this.allRows;
        if (this.timeEntryFilter === 'with') {
            rows = rows.filter((row) => row.hasTimeEntry);
        } else if (this.timeEntryFilter === 'without') {
            rows = rows.filter((row) => !row.hasTimeEntry);
        }
        const direction = this.sortDirection === 'asc' ? 1 : -1;
        return [...rows].sort((left, right) => {
            const leftValue = left[this.sortField] || '';
            const rightValue = right[this.sortField] || '';
            if (leftValue < rightValue) {
                return -1 * direction;
            }
            if (leftValue > rightValue) {
                return 1 * direction;
            }
            return 0;
        });
    }

    get isEmpty() {
        return !this.isLoading && this.visibleRows.length === 0;
    }

    get dateSortMark() {
        return this.sortMark('activityDate');
    }

    get subjectSortMark() {
        return this.sortMark('subject');
    }

    sortMark(field) {
        if (this.sortField !== field) {
            return '';
        }
        return this.sortDirection === 'asc' ? 'â–²' : 'â–¼';
    }

    handleFromDateChange(event) {
        this.fromDate = event.target.value;
        this.loadRows();
    }

    handleToDateChange(event) {
        this.toDate = event.target.value;
        this.loadRows();
    }

    handleTimeEntryFilterChange(event) {
        this.timeEntryFilter = event.detail.value;
    }

    handleSortDate() {
        this.toggleSort('activityDate');
    }

    handleSortSubject() {
        this.toggleSort('subject');
    }

    toggleSort(field) {
        if (this.sortField === field) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            this.sortField = field;
            this.sortDirection = field === 'subject' ? 'asc' : 'desc';
        }
    }

    async loadRows() {
        this.isLoading = true;
        try {
            const data = await getMyActivities({
                startDate: this.fromDate,
                endDate: this.toDate
            });
            this.allRows = (data || []).map((row) => this.decorateRow(row));
        } catch (error) {
            this.toast('Error', this.extractError(error), 'error');
            this.allRows = [];
        } finally {
            this.isLoading = false;
        }
    }

    decorateRow(row) {
        const projectId = row.suggestedProjectId || null;
        return {
            ...row,
            rowKey: row.id,
            suggestedProjectId: projectId,
            suggestedProjectName: row.suggestedProjectName || null,
            projectTaskId: row.projectTaskId || null,
            projectTaskName: row.projectTaskName || null,
            workingLocation: row.workingLocation || '',
            displayDate: this.formatDate(row.activityDate),
            showLocation: row.dayName !== 'Saturday' && row.dayName !== 'Sunday',
            noProject: !projectId
        };
    }

    handleInlineChange(event) {
        const row = this.findRow(event.currentTarget.dataset.rowId);
        if (!row) {
            return;
        }
        const field = event.currentTarget.dataset.field;
        row[field] = event.detail.value;
        this.allRows = [...this.allRows];
        this.saveRow(row);
    }

    handleProjectChange(event) {
        const row = this.findRow(event.currentTarget.dataset.rowId);
        if (!row) {
            return;
        }
        row.suggestedProjectId = event.detail.value || null;
        row.suggestedProjectName = event.detail.selection || null;
        row.projectTaskId = null;
        row.projectTaskName = null;
        this.allRows = this.allRows.map((item) =>
            item.id === row.id ? this.decorateRow(item) : item
        );
        this.saveRow(this.findRow(row.id));
    }

    handleTaskChange(event) {
        const row = this.findRow(event.currentTarget.dataset.rowId);
        if (!row) {
            return;
        }
        row.projectTaskId = event.detail.value || null;
        row.projectTaskName = event.detail.selection || null;
        this.allRows = [...this.allRows];
        this.saveRow(row);
    }

    async handleDelete(event) {
        const row = this.findRow(event.currentTarget.dataset.rowId);
        if (!row) {
            return;
        }
        const confirmed = await LightningConfirm.open({
            label: 'Delete event',
            message: `Delete "${row.subject || 'this event'}"?`,
            theme: 'error'
        });
        if (!confirmed) {
            return;
        }
        try {
            await deleteEvent({ recordId: row.id });
            this.allRows = this.allRows.filter((item) => item.id !== row.id);
            this.toast('Deleted', 'Event deleted.', 'success');
        } catch (error) {
            this.toast('Error', this.extractError(error), 'error');
        }
    }

    findRow(rowId) {
        return this.allRows.find((row) => row.id === rowId);
    }

    async saveRow(row) {
        if (this.savesInFlight[row.id]) {
            return;
        }
        this.savesInFlight[row.id] = true;
        try {
            if (row.showLocation) {
                await setWorkingLocation({
                    workDate: row.workDate,
                    locationValue: row.workingLocation || null
                });
            }
            if (!(parseFloat(row.hours) > 0)) {
                return;
            }
            const result = await createTimeEntry({
                request: {
                    timeEntryId: row.timeEntryId,
                    workDate: row.workDate,
                    hoursWorked: parseFloat(row.hours),
                    notes: row.subject,
                    timeCategory: row.timeCategory,
                    internal: row.internal === true,
                    projectId: row.suggestedProjectId,
                    projectTaskId: row.projectTaskId
                }
            });
            if (result && result.timeEntryId && result.timeEntryId !== row.timeEntryId) {
                await linkTimeEntry({ eventId: row.id, timeEntryId: result.timeEntryId });
                row.timeEntryId = result.timeEntryId;
                row.hasTimeEntry = true;
                this.allRows = [...this.allRows];
            }
        } catch (error) {
            this.toast('Error', this.extractError(error), 'error');
        } finally {
            this.savesInFlight[row.id] = false;
        }
    }

    formatDate(value) {
        if (!value) {
            return '';
        }
        return new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }).format(new Date(value));
    }

    toIsoDate(value) {
        const year = value.getFullYear();
        const month = String(value.getMonth() + 1).padStart(2, '0');
        const day = String(value.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    extractError(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'Something went wrong.';
    }
}
```

## force-app\main\default\lwc\egOutlookEventReview\egOutlookEventReview.js-meta.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>63.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Outlook Event Review</masterLabel>
    <targets>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
        <target>lightning__Tab</target>
    </targets>
</LightningComponentBundle>
```

## force-app\main\default\lwc\datatablePractice\datatablePractice.html

```html
<template>
    <lightning-card title="datatable practice">
        <div class="slds-p-around_medium">
            <lightning-datatable
                data={data}
                columns={columns}
                key-field="id"
                hide-checkbox-column
            ></lightning-datatable>
        </div>
    </lightning-card>
</template>
```

## force-app\main\default\lwc\datatablePractice\datatablePractice.js

```javascript
import { LightningElement } from 'lwc';

export default class DatatablePractice extends LightningElement {
    columns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Email', fieldName: 'email' },
        { label: 'Phone', fieldName: 'phone' },
        { label: 'Company', fieldName: 'company' }
    ];

    data = [
        {
            id: '1',
            name: 'John Doe',
            email: 'john.doe@example.com',
            phone: '1234567890',
            company: 'ABC Inc'
        },
        {
            id: '2',
            name: 'Jane Smith',
            email: 'jane.smith@example.com',
            phone: '0987654321',
            company: 'XYZ Corp'
        }
    ];
}
```

## force-app\main\default\lwc\datatablePractice\datatablePractice.js-meta.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>63.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Datatable Practice</masterLabel>
    <targets>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
        <target>lightning__Tab</target>
    </targets>
</LightningComponentBundle>
```

# Outlook time entry

Source lives in metadata-audit\ (retrieved from the org), not force-app\.

- TimeEntryController
- TimeEntryControllerTest
- TimeEntryService
- TimeEntryServiceTest
- TimeEntrySelector
- TimeEntryKey
- TimeEntryKeyTest
- TimeEntryRequest
- TimeEntrySummary
- TimeCardSelector
- TestDataFactory
- outlookTimeEntry (LWC)
