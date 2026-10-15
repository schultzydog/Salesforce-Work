/**
 * Pulls KnowBe4 training campaigns in scope, fetches their enrollments, and
 * upserts Module + User Result records. Only writes rows that actually changed.
 *
 * Campaigns are in scope when they started on/after the cutoff, or when they
 * are still open (status is not Closed or Completed). Enrollments older than
 * the cutoff are dropped even if the campaign is in scope.
 *
 * Cutoff is hardcoded to 2024-01-01 for the first production pull. Replace with
 * a rolling 18-month window on the follow-up deploy.
 */
public without sharing class KnowBe4SyncService {

    public static final Datetime CUTOFF = Datetime.newInstanceGmt(2024, 1, 1, 0, 0, 0);
    public static final Integer CAMPAIGNS_PER_JOB = 15;
    public static final Integer MAX_CAMPAIGN_PAGES = 20;
    public static final Integer MAX_USER_PAGES = 20;

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
        Map<String, UserMetrics> metricsByEmail = loadUserMetricsByEmail();
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
            // Left unpopulated when KnowBe4 has no metrics for the address, so
            // DML omits the fields and a previously synced value survives.
            UserMetrics metrics = metricsByEmail.get(normalizeEmail(email));
            if (metrics != null) {
                draft.result.Current_PPP__c = metrics.phishPronePercentage;
                draft.result.Risk_Score__c = metrics.riskScore;
            }
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

    /** Current phish-prone percentage and risk score, which live on the user. */
    private class UserMetrics {
        Decimal phishPronePercentage;
        Decimal riskScore;
    }

    private static Map<String, UserMetrics> loadUserMetricsByEmail() {
        Map<String, UserMetrics> byEmail = new Map<String, UserMetrics>();

        for (Integer pageNumber = 1; pageNumber <= MAX_USER_PAGES; pageNumber++) {
            List<Object> rows =
                (List<Object>) JSON.deserializeUntyped(KnowBe4Client.fetchUsers(pageNumber));
            for (Object row : rows) {
                Map<String, Object> node = (Map<String, Object>) row;
                String key = normalizeEmail((String) node.get('email'));
                if (key == null) {
                    continue;
                }
                UserMetrics metrics = new UserMetrics();
                metrics.phishPronePercentage = toDecimal(node.get('phish_prone_percentage'));
                metrics.riskScore = toDecimal(node.get('current_risk_score'));
                byEmail.put(key, metrics);
            }
            if (rows.size() < KnowBe4Client.MAX_PAGE_SIZE) {
                break;
            }
        }
        return byEmail;
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
                   Started__c, Completed__c, Status__c, Score__c,
                   Current_PPP__c, Risk_Score__c
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
            || existing.Score__c != proposed.Score__c
            // A null means KnowBe4 told us nothing this run, not that the
            // score is now blank, so it is not a reason to rewrite the row.
            || (proposed.Current_PPP__c != null
                && existing.Current_PPP__c != proposed.Current_PPP__c)
            || (proposed.Risk_Score__c != null
                && existing.Risk_Score__c != proposed.Risk_Score__c);
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

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return null;
        }
        String raw = String.valueOf(value);
        return String.isBlank(raw) || raw == 'null' ? null : Decimal.valueOf(raw);
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
