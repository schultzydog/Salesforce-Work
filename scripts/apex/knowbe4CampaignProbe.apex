// Two questions:
//   1. How many training campaigns exist, and what statuses do they carry?
//   2. Does the enrollments endpoint honour a campaign_id filter?
//
//   sf apex run --file scripts/apex/knowbe4CampaignProbe.apex --target-org EG-Sandbox

List<Object> campaigns = (List<Object>) JSON.deserializeUntyped(
    KnowBe4Client.get('/v1/training/campaigns?per_page=500')
);
System.debug(LoggingLevel.ERROR, 'KB4_CAMPAIGN_TOTAL=' + campaigns.size());

Map<String, Integer> countByStatus = new Map<String, Integer>();
Integer newestId;
String newestStart;

for (Object row : campaigns) {
    Map<String, Object> c = (Map<String, Object>) row;

    String status = String.valueOf(c.get('status'));
    countByStatus.put(status, countByStatus.containsKey(status) ? countByStatus.get(status) + 1 : 1);

    String startDate = String.valueOf(c.get('start_date'));
    if (newestStart == null || startDate > newestStart) {
        newestStart = startDate;
        newestId = Integer.valueOf(c.get('campaign_id'));
    }
}

System.debug(LoggingLevel.ERROR, 'KB4_STATUS_COUNTS=' + countByStatus);
System.debug(LoggingLevel.ERROR, 'KB4_NEWEST_CAMPAIGN=' + newestId + ' starting ' + newestStart);

// Does the filter actually narrow the result set?
List<Object> filtered = (List<Object>) JSON.deserializeUntyped(
    KnowBe4Client.get('/v1/training/enrollments?campaign_id=' + newestId + '&per_page=500')
);
System.debug(LoggingLevel.ERROR, 'KB4_FILTERED_ENROLLMENTS=' + filtered.size());

if (!filtered.isEmpty()) {
    Map<String, Object> first = (Map<String, Object>) filtered[0];
    System.debug(LoggingLevel.ERROR, 'KB4_FILTER_SAMPLE_CAMPAIGN=' + first.get('campaign_name'));
}
