// The Status__c picklist holds 'passed' / 'past_due' but the API returns 'Passed'.
// Collecting every status value actually present so the mapping is complete.
//
//   sf apex run --file scripts/apex/knowbe4StatusProbe.apex --target-org EG-Sandbox

String cutoff = '2025-01-01';

List<Integer> campaignIds = new List<Integer>();
for (Integer page = 1; page <= 10; page++) {
    List<Object> rows = (List<Object>) JSON.deserializeUntyped(
        KnowBe4Client.get('/v1/training/campaigns?page=' + page)
    );
    if (rows.isEmpty()) {
        break;
    }
    for (Object row : rows) {
        Map<String, Object> c = (Map<String, Object>) row;
        if (String.valueOf(c.get('start_date')) >= cutoff) {
            campaignIds.add(Integer.valueOf(c.get('campaign_id')));
        }
    }
}

Map<String, Integer> statusCounts = new Map<String, Integer>();
Set<String> contentTypes = new Set<String>();
Integer missingEmail = 0;

for (Integer campaignId : campaignIds) {
    for (Object row : (List<Object>) JSON.deserializeUntyped(
        KnowBe4Client.get('/v1/training/enrollments?campaign_id=' + campaignId + '&per_page=500')
    )) {
        Map<String, Object> e = (Map<String, Object>) row;

        String status = String.valueOf(e.get('status'));
        statusCounts.put(status, statusCounts.containsKey(status) ? statusCounts.get(status) + 1 : 1);
        contentTypes.add(String.valueOf(e.get('content_type')));

        Map<String, Object> user = (Map<String, Object>) e.get('user');
        if (user == null || String.isBlank(String.valueOf(user.get('email')))) {
            missingEmail++;
        }
    }
}

System.debug(LoggingLevel.ERROR, 'KB4_STATUSES=' + statusCounts);
System.debug(LoggingLevel.ERROR, 'KB4_CONTENT_TYPES=' + contentTypes);
System.debug(LoggingLevel.ERROR, 'KB4_MISSING_EMAIL=' + missingEmail);
