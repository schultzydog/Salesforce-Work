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

    /**
     * Fetches one page of users. Enrollments carry no phish-prone percentage or
     * risk score, so those come from here and are keyed back by email.
     */
    public static String fetchUsers(Integer pageNumber) {
        return get('/v1/users?page=' + pageNumber + '&per_page=' + MAX_PAGE_SIZE);
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