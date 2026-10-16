/**
 * Concept: Google search via SerpAPI for a Contact, then shape the JSON into
 * facts and sources the LWC modal can render. Does not write back to the record.
 */
public with sharing class ContactEnrichmentService {

    private static final String SERPAPI_HOST = 'https://serpapi.com';
    private static final Integer MAX_SOURCES = 8;

    public class EnrichmentException extends Exception {}

    public class ContactSnapshot {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String title;
        @AuraEnabled public String accountName;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;
        @AuraEnabled public String mobilePhone;
        @AuraEnabled public String mailingCity;
        @AuraEnabled public String mailingCountry;
    }

    public class Fact {
        @AuraEnabled public String rowId;
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String sourceLabel;
        @AuraEnabled public String sourceUrl;
        @AuraEnabled public Boolean alreadyOnRecord;
    }

    public class SourceHit {
        @AuraEnabled public Integer position;
        @AuraEnabled public String title;
        @AuraEnabled public String url;
        @AuraEnabled public String snippet;
        @AuraEnabled public String displayedLink;
        @AuraEnabled public String kind;
    }

    public class EnrichmentResult {
        @AuraEnabled public ContactSnapshot contact;
        @AuraEnabled public String query;
        @AuraEnabled public String knowledgeTitle;
        @AuraEnabled public String knowledgeType;
        @AuraEnabled public String knowledgeDescription;
        @AuraEnabled public String knowledgeSource;
        @AuraEnabled public List<Fact> facts;
        @AuraEnabled public List<SourceHit> sources;
        @AuraEnabled public Long totalResults;
    }

    @AuraEnabled
    public static EnrichmentResult enrich(Id contactId) {
        if (contactId == null) {
            throw userError('Contact Id is required.');
        }

        ContactSnapshot snap = loadContact(contactId);
        String query = buildQuery(snap);
        if (String.isBlank(query)) {
            throw userError('This contact needs a name, email, or phone before it can be enriched.');
        }

        Map<String, Object> payload = search(query);
        return toResult(snap, query, payload);
    }

    @TestVisible
    static ContactSnapshot loadContact(Id contactId) {
        List<Contact> rows = [
            SELECT Id, Name, FirstName, LastName, Title, Email, Phone, MobilePhone,
                   MailingCity, MailingCountry, Account.Name
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            throw userError('Contact was not found.');
        }
        Contact row = rows[0];
        ContactSnapshot snap = new ContactSnapshot();
        snap.id = row.Id;
        snap.name = row.Name;
        snap.title = row.Title;
        snap.accountName = row.Account == null ? null : row.Account.Name;
        snap.email = row.Email;
        snap.phone = row.Phone;
        snap.mobilePhone = row.MobilePhone;
        snap.mailingCity = row.MailingCity;
        snap.mailingCountry = row.MailingCountry;
        return snap;
    }

    @TestVisible
    static String buildQuery(ContactSnapshot snap) {
        List<String> identity = new List<String>();
        if (!String.isBlank(snap.name)) {
            identity.add('"' + snap.name.trim() + '"');
        }
        if (!String.isBlank(snap.accountName)) {
            identity.add('"' + snap.accountName.trim() + '"');
        }
        if (!String.isBlank(snap.title)) {
            identity.add(snap.title.trim());
        }

        List<String> identifiers = new List<String>();
        if (!String.isBlank(snap.email)) {
            identifiers.add('"' + snap.email.trim() + '"');
        }
        addPhoneTerm(identifiers, snap.phone);
        if (!samePhone(snap.phone, snap.mobilePhone)) {
            addPhoneTerm(identifiers, snap.mobilePhone);
        }

        if (identity.isEmpty()) {
            return String.join(identifiers, ' OR ');
        }
        if (identifiers.isEmpty()) {
            return String.join(identity, ' ');
        }
        return String.join(identity, ' ') + ' OR ' + String.join(identifiers, ' OR ');
    }

    @TestVisible
    static String apiKey() {
        SerpAPI_Settings__c settings = SerpAPI_Settings__c.getInstance();
        String key = settings == null ? null : settings.API_Key__c;
        if (String.isBlank(key) && !Test.isRunningTest()) {
            throw userError(
                'Set the SerpAPI key: Setup → Custom Settings → SerpAPI Settings → Manage → New (org default).'
            );
        }
        return String.isBlank(key) ? 'test-key' : key;
    }

    @TestVisible
    static Map<String, Object> search(String query) {
        String key = apiKey();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setTimeout(60000);
        req.setHeader('Accept', 'application/json');
        req.setEndpoint(
            SERPAPI_HOST
                + '/search.json?engine=google&hl=en&gl=us&no_cache=false'
                + '&q=' + EncodingUtil.urlEncode(query, 'UTF-8')
                + '&api_key=' + EncodingUtil.urlEncode(key, 'UTF-8')
        );

        HttpResponse res;
        try {
            res = new Http().send(req);
        } catch (System.CalloutException e) {
            throw userError('SerpAPI callout failed. ' + e.getMessage());
        }

        if (res.getStatusCode() != 200) {
            throw userError(
                'SerpAPI returned HTTP ' + res.getStatusCode() + ': ' + shorten(res.getBody())
            );
        }

        Object parsed = JSON.deserializeUntyped(res.getBody());
        if (!(parsed instanceof Map<String, Object>)) {
            throw userError('SerpAPI returned JSON that was not an object.');
        }
        return (Map<String, Object>) parsed;
    }

    @TestVisible
    static EnrichmentResult toResult(ContactSnapshot snap, String query, Map<String, Object> payload) {
        EnrichmentResult result = new EnrichmentResult();
        result.contact = snap;
        result.query = query;
        result.facts = new List<Fact>();
        result.sources = new List<SourceHit>();

        Map<String, Object> searchInfo = asMap(payload.get('search_information'));
        result.totalResults = asLong(searchInfo.get('total_results'));

        Map<String, Object> kg = asMap(payload.get('knowledge_graph'));
        if (!kg.isEmpty()) {
            result.knowledgeTitle = asString(kg.get('title'));
            result.knowledgeType = asString(kg.get('type'));
            result.knowledgeDescription = asString(kg.get('description'));
            Map<String, Object> kgSource = asMap(kg.get('source'));
            result.knowledgeSource = asString(kgSource.get('name'));
            String kgSourceLink = asString(kgSource.get('link'));
            if (String.isBlank(kgSourceLink)) {
                kgSourceLink = asString(kg.get('website'));
            }

            addFact(result, snap, 'name', 'Name', result.knowledgeTitle, result.knowledgeSource, kgSourceLink);
            addFact(result, snap, 'type', 'Type', asString(kg.get('type')), result.knowledgeSource, kgSourceLink);
            addFact(result, snap, 'description', 'Summary', result.knowledgeDescription, result.knowledgeSource, kgSourceLink);
            addFact(result, snap, 'website', 'Website', asString(kg.get('website')), result.knowledgeSource, asString(kg.get('website')));
            addRemainingKnowledgeFacts(result, snap, kg, result.knowledgeSource, kgSourceLink);

            Object profiles = kg.get('profiles');
            if (profiles instanceof List<Object>) {
                for (Object rawProfile : (List<Object>) profiles) {
                    Map<String, Object> profile = asMap(rawProfile);
                    String profileName = asString(profile.get('name'));
                    String profileLink = asString(profile.get('link'));
                    if (!String.isBlank(profileLink)) {
                        String key = profileName != null && profileName.toLowerCase().contains('linkedin')
                            ? 'linkedin'
                            : 'profile';
                        addFact(result, snap, key, String.isBlank(profileName) ? 'Profile' : profileName, profileLink, profileName, profileLink);
                    }
                }
            }
        }

        Object organic = payload.get('organic_results');
        if (organic instanceof List<Object>) {
            Integer count = 0;
            for (Object rawHit : (List<Object>) organic) {
                if (count >= MAX_SOURCES) {
                    break;
                }
                Map<String, Object> hit = asMap(rawHit);
                SourceHit source = new SourceHit();
                source.position = asInteger(hit.get('position'));
                source.title = asString(hit.get('title'));
                source.url = asString(hit.get('link'));
                source.snippet = asString(hit.get('snippet'));
                source.displayedLink = asString(hit.get('displayed_link'));
                source.kind = classifySource(source.url);
                if (String.isBlank(source.title) && String.isBlank(source.url)) {
                    continue;
                }
                result.sources.add(source);
                count++;

                if (source.kind == 'linkedin') {
                    addFact(result, snap, 'linkedin', 'LinkedIn', source.url, source.title, source.url);
                    addFact(result, snap, 'title', 'Title', titleFromLinkedIn(source.title, source.snippet), source.title, source.url);
                }
            }
        }

        return result;
    }

    private static void addFact(
        EnrichmentResult result,
        ContactSnapshot snap,
        String key,
        String label,
        String value,
        String sourceLabel,
        String sourceUrl
    ) {
        if (String.isBlank(value)) {
            return;
        }
        for (Fact existing : result.facts) {
            if (existing.key == key && existing.value == value) {
                return;
            }
        }
        Fact fact = new Fact();
        fact.rowId = key + '-' + String.valueOf(result.facts.size());
        fact.key = key;
        fact.label = label;
        fact.value = value;
        fact.sourceLabel = sourceLabel;
        fact.sourceUrl = sourceUrl;
        fact.alreadyOnRecord = matchesRecord(snap, key, value);
        result.facts.add(fact);
    }

    private static void addPhoneTerm(List<String> parts, String phone) {
        if (String.isBlank(phone)) {
            return;
        }
        parts.add('"' + phone.trim() + '"');
        String digits = digitsOnly(phone);
        if (digits.length() >= 7 && digits != phone.trim()) {
            parts.add('"' + digits + '"');
        }
    }

    private static Boolean samePhone(String left, String right) {
        if (String.isBlank(right)) {
            return true;
        }
        if (String.isBlank(left)) {
            return false;
        }
        return digitsOnly(left) == digitsOnly(right);
    }

    private static String digitsOnly(String value) {
        return value == null ? '' : value.replaceAll('[^0-9]', '');
    }

    private static Boolean matchesRecord(ContactSnapshot snap, String key, String value) {
        if (snap == null || String.isBlank(value)) {
            return false;
        }
        String needle = value.trim().toLowerCase();
        if (key == 'name') {
            return containsIgnoreCase(snap.name, needle);
        }
        if (key == 'title') {
            return containsIgnoreCase(snap.title, needle);
        }
        if (key == 'email') {
            return containsIgnoreCase(snap.email, needle);
        }
        if (key == 'phone') {
            return containsIgnoreCase(snap.phone, needle) || containsIgnoreCase(snap.mobilePhone, needle);
        }
        if (key == 'linkedin' || key == 'website' || key == 'profile') {
            return containsIgnoreCase(snap.email, needle);
        }
        return containsIgnoreCase(snap.accountName, needle) || containsIgnoreCase(snap.title, needle);
    }

    private static Boolean containsIgnoreCase(String haystack, String needle) {
        return !String.isBlank(haystack) && haystack.toLowerCase().contains(needle);
    }

    private static String classifySource(String url) {
        if (String.isBlank(url)) {
            return 'web';
        }
        String lower = url.toLowerCase();
        if (lower.contains('linkedin.com/in/')) {
            return 'linkedin';
        }
        if (lower.contains('linkedin.com')) {
            return 'linkedin-other';
        }
        if (lower.contains('wikipedia.org')) {
            return 'wikipedia';
        }
        if (lower.contains('twitter.com') || lower.contains('x.com/')) {
            return 'twitter';
        }
        return 'web';
    }

    private static String titleFromLinkedIn(String title, String snippet) {
        String fromTitle = extractRole(title);
        if (!String.isBlank(fromTitle)) {
            return fromTitle;
        }
        return extractRole(snippet);
    }

    private static String extractRole(String text) {
        if (String.isBlank(text) || !text.contains(' at ')) {
            return null;
        }
        return text.substringBefore(' at ').trim();
    }

    private static Map<String, Object> asMap(Object value) {
        return value instanceof Map<String, Object>
            ? (Map<String, Object>) value
            : new Map<String, Object>();
    }

    private static String asString(Object value) {
        return value == null ? null : String.valueOf(value);
    }

    private static Integer asInteger(Object value) {
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Decimal) {
            return ((Decimal) value).intValue();
        }
        return null;
    }

    private static Long asLong(Object value) {
        if (value instanceof Long) {
            return (Long) value;
        }
        if (value instanceof Integer) {
            return Long.valueOf(String.valueOf(value));
        }
        if (value instanceof Decimal) {
            return ((Decimal) value).longValue();
        }
        return null;
    }

    private static void addRemainingKnowledgeFacts(
        EnrichmentResult result,
        ContactSnapshot snap,
        Map<String, Object> kg,
        String sourceLabel,
        String sourceUrl
    ) {
        Set<String> skip = new Set<String>{
            'title', 'type', 'description', 'source', 'website', 'profiles',
            'thumbnail', 'header_images', 'image', 'kgmid',
            'knowledge_graph_search_link', 'serpapi_knowledge_graph_search_link'
        };
        for (String fieldName : kg.keySet()) {
            if (skip.contains(fieldName)) {
                continue;
            }
            Object raw = kg.get(fieldName);
            if (!(raw instanceof String) && !(raw instanceof Integer) && !(raw instanceof Decimal) && !(raw instanceof Long)) {
                continue;
            }
            addFact(result, snap, fieldName, prettyLabel(fieldName), String.valueOf(raw), sourceLabel, sourceUrl);
        }
    }

    private static String prettyLabel(String apiName) {
        return apiName == null ? '' : apiName.replace('_', ' ').capitalize();
    }

    private static AuraHandledException userError(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }

    private static String shorten(String body) {
        if (String.isBlank(body)) {
            return '(empty body)';
        }
        return body.length() > 240 ? body.substring(0, 240) + '…' : body;
    }
}